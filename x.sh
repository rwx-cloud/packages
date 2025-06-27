find . -name mint-ci-cd.config.yml | while read -r filepath; do
  dir=$(dirname "$filepath")
  mv "$filepath" "$dir/rwx-ci-cd.config.yml"
done
