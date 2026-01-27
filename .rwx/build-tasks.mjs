import { glob } from "glob";
import fs from "fs/promises";
import path from "path";
import yaml from "yaml";

const BUILD_DIR = process.env.BUILD_DIR;
const GIT_DIFF_FILE = process.env.GIT_DIFF_FILE;
const RWX_DYNAMIC_TASKS = process.env.RWX_DYNAMIC_TASKS;

if (!BUILD_DIR || !GIT_DIFF_FILE || !RWX_DYNAMIC_TASKS) {
  console.error("Must set BUILD_DIR and GIT_DIFF_FILE and RWX_DYNAMIC_TASKS");
  process.exit(1);
}

let packages = [];
const leafDirs = new Set();
const leavesToBuild = new Set();
const DEFAULT_BASE_LAYER = {
  os: "ubuntu 24.04",
  tag: "1.1",
  arch: "x86_64",
};

async function exists(pathname) {
  try {
    await fs.stat(pathname);
    return true;
  } catch {
    return false;
  }
}

for (const file of (await glob("*/*/rwx-package.yml")).sort()) {
  const name = path.dirname(file);
  const key = name.replace("/", "-");
  let buildDependencies = [];
  if (await exists(path.join(name, "build/dependencies.yml"))) {
    buildDependencies = yaml.parse(
      await fs.readFile(path.join(name, "build/dependencies.yml"), {
        encoding: "utf8",
      }),
    );
  }

  let config;
  if (await exists(path.join(name, "rwx-ci-cd.config.yml"))) {
    config = yaml.parse(
      await fs.readFile(path.join(name, "rwx-ci-cd.config.yml"), {
        encoding: "utf8",
      }),
    );
  }

  packages.push({
    name,
    key,
    dir: name,
    artifactFile: `${BUILD_DIR}/${key}.yml`,
    buildDependencies,
    config,
  });
  leafDirs.add(name);
}

let buildAll = false;
const filesNotToTriggerBuildAll = ["cspell.yaml"];

for (const line of (await fs.readFile(GIT_DIFF_FILE, "utf8")).split("\n")) {
  if (line === "") {
    continue;
  }

  const foundNonLeafFile = () => {
    console.log(`Found non-leaf file in diff: ${line}`);
    buildAll = true;
  };

  if (line.split("/").length >= 2) {
    const leafName = line.split("/").slice(0, 2).join("/");
    if (leafDirs.has(leafName)) {
      leavesToBuild.add(leafName);
    } else {
      foundNonLeafFile();
      break;
    }
  } else {
    if (filesNotToTriggerBuildAll.includes(line)) {
      continue;
    } else {
      foundNonLeafFile();
      break;
    }
  }
}

if (buildAll) {
  console.log("Building all packages");
} else {
  console.log("Only building packages with changes:");
  leavesToBuild.forEach((leaf) => console.log(leaf));

  packages = packages.filter((leaf) => leavesToBuild.has(leaf.name));
}

const stringifyBase = (base) =>
  `${base.os}-${base.arch}-${base.tag}`.replaceAll(/[^a-zA-Z0-9-]/g, "-");

const generateTestsTask = async (leaf) => {
  const artifacts = [];
  const leafBuildDir = `${BUILD_DIR}/${leaf.key}`;

  let leafTestTasks = [];
  const commands = [];
  const testConfigs = leaf.config?.tests ?? [];
  if (
    testConfigs.length === 0 &&
    (await exists(path.join(leaf.dir, "rwx-ci-cd.template.yml")))
  ) {
    testConfigs.push({
      key: stringifyBase(DEFAULT_BASE_LAYER),
      template: "rwx-ci-cd.template.yml",
      base: DEFAULT_BASE_LAYER,
    });
  }

  for (const testConfig of testConfigs) {
    const outputPath = path.join(leafBuildDir, `${testConfig.key}.yml`);

    // Generate an embedded run file artifact.
    commands.push(`cat <<'EOF' > "${outputPath}"`);
    if (testConfig.base) {
      commands.push(yaml.stringify({ base: testConfig.base }, null, 2));
    }
    commands.push(
      yaml.stringify({
        "tool-cache": {
          vault: "rwx-packages-main",
        },
      }),
    );
    commands.push(`tasks:`);
    commands.push(`EOF`);
    commands.push(
      `envsubst '$LEAF_DIGEST' < "${path.join(leaf.dir, testConfig.template)}" | sed -e 's/^/  /' | tee -a "${outputPath}"`,
    );

    artifacts.push({
      key: testConfig.key,
      path: outputPath,
    });

    // Add the embedded run to the package's test tasks.
    commands.push(`cat <<'EOF' >> "$RWX_DYNAMIC_TASKS/${leaf.key}.yml"`);
    commands.push(`- key: test-${testConfig.key}`);
    commands.push(
      `  call: \\\${{ tasks.generate-tests.artifacts.${testConfig.key} }}`,
    );
    commands.push("");
    commands.push(`EOF`);

    commands.push("");

    leafTestTasks.push(`test-${testConfig.key}`);
  }

  return {
    key: "generate-tests",
    use: "upload",
    filter: [leaf.dir, "publish-tasks.template.yml"],
    run: `
      mkdir -p "${leafBuildDir}"

      ${commands.join("\n")}

      export LEAF_TEST_TASKS="${leafTestTasks.join(",")}"
      envsubst '$LEAF_TEST_TASKS' < publish-tasks.template.yml | tee -a $RWX_DYNAMIC_TASKS/${leaf.key}.yml
    `,
    outputs: { artifacts },
    env: {
      LEAF_DIGEST: "${{ tasks.upload.values.leaf-digest }}",
    },
  };
};

const generateLeafRun = async (leaf) => {
  return {
    base: DEFAULT_BASE_LAYER,
    tasks: [
      {
        key: "packages",
        run: `
          sudo apt-get update
          sudo apt-get install gettext-base jq zip
          sudo apt-get clean
        `,
      },
      {
        key: "code",
        call: "git/clone 2.0.0",
        with: {
          "preserve-git-dir": true,
          repository: "https://github.com/rwx-cloud/packages.git",
          ref: "${{ init.sha }}",
          "github-token": "${{ github['rwx-cloud'].token }}",
        },
      },
      {
        key: "timestamp",
        use: "code",
        run: `
          latest_timestamp=$(git ls-files -z ${leaf.dir} | xargs -0 -n1 -I{} -- git log -1 --date=format:"%Y%m%d%H%M" --format="%ad" {} | sort | tail -n 1)
          echo -n "$latest_timestamp" | tee $RWX_VALUES/timestamp
        `,
      },
      ...leaf.buildDependencies,
      {
        key: "build",
        use: [
          "packages",
          "code",
          ...leaf.buildDependencies.map((dep) => dep.key),
        ],
        filter: [leaf.dir],
        run: `
          cd ${leaf.dir}
          if [[ -f build/run.sh ]]; then
            echo "Running leaf build script"
            ./build/run.sh
          else
            echo "Leaf has no build script"
          fi
        `,
      },
      {
        key: "zip",
        use: "build",
        filter: [leaf.dir],
        run: `
          timestamp="\${{ tasks.timestamp.values.timestamp }}"
          echo "Setting timestamp on files to $timestamp"
          find ${leaf.dir} -exec touch -t "$timestamp" {} \\;
          cd ${leaf.dir} && zip -X -r ../../${leaf.key}.zip .
        `,
      },
      {
        key: "upload",
        use: "zip",
        filter: [`${leaf.key}.zip`],
        env: {
          RWX_ACCESS_TOKEN: {
            "cache-key": "excluded",
            value:
              "${{ vaults.mint_leaves_development.secrets.RWX_ACCESS_TOKEN }}",
          },
        },
        run: `
          curl \
            --request POST \
            --fail-with-body \
            --header "Authorization: Bearer $RWX_ACCESS_TOKEN" \
            --header 'Accept: application/json' \
            -F 'file=@${leaf.key}.zip' \
            https://cloud.rwx.com/mint/api/leaves | tee leaves-result.json

          leaf_digest=$(cat leaves-result.json | jq -r '.digest')
          echo -n "$leaf_digest" > "$RWX_VALUES/leaf-digest"
        `,
      },
      await generateTestsTask(leaf),
    ],
  };
};

const artifacts = [];
const leafRuns = [];

for (const leaf of packages) {
  const content = yaml.stringify(await generateLeafRun(leaf));
  await fs.writeFile(leaf.artifactFile, content, "utf8");

  leafRuns.push({
    key: leaf.key,
    call: `\${{ tasks.generate-leaf-runs.artifacts.${leaf.key} }}`,
    init: {
      "publish-leaves": "${{ init.publish-leaves }}",
      sha: "${{ init.sha }}",
    },
  });

  artifacts.push({
    key: leaf.key,
    path: leaf.artifactFile,
  });
}

await fs.writeFile(`${BUILD_DIR}/leaf-runs.yaml`, yaml.stringify(leafRuns));

// this is needed since artifacts cannot otherwise be declared dynamically
const generateTask = {
  key: "generate-leaf-runs",
  use: "build-leaf-runs",
  run: `
    ${artifacts.map((a) => `touch ${a.path}`).join("\n")}
    cp ${BUILD_DIR}/leaf-runs.yaml $RWX_DYNAMIC_TASKS
  `,
  outputs: { artifacts },
};

await fs.writeFile(
  `${RWX_DYNAMIC_TASKS}/generate-task.yaml`,
  yaml.stringify([generateTask]),
);
