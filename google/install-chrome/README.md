# google/install-chrome

You'll need to specify `chrome-version`. `chrome-version` can be one of:

- A Chrome release channel: `stable`, `beta`, `dev` or `canary`
- A Chrome version: `130`, `130.0.6669`, or `130.0.6669.0`.

Versions 115 and greater are supported.

## Without chromedriver

```yaml
tasks:
  - key: chrome
    call: google/install-chrome 2.1.3
    with:
      chrome-version: 130
```

## With a compatible chromedriver

```yaml
tasks:
  - key: chrome
    call: google/install-chrome 2.1.3
    with:
      chrome-version: 130
      install-chromedriver: true
```

## Installing multiple chromes

If you are installing multiple versions of chrome and using them within the same task, you'll need to choose where to install them and may want to exclude it from PATH (as the binary names will conflict). Some details about the chrome installation are exposed as output values:

```yaml
tasks:
  - key: chrome-129
    call: google/install-chrome 2.1.3
    with:
      chrome-version: 129
      install-chromedriver: true
      chrome-directory: /opt/chrome-129
      chromedriver-directory: /opt/chromedriver-129
      add-to-path: false

  - key: chrome-130
    call: google/install-chrome 2.1.3
    with:
      chrome-version: 130
      install-chromedriver: true
      chrome-directory: /opt/chrome-130
      chromedriver-directory: /opt/chromedriver-130
      add-to-path: false

  - key: use-chromes
    use: [chrome-130, chrome-129]
    run: |
      /opt/chrome-129/chrome --version | grep "129\."
      /opt/chromedriver-129/chromedriver --version | grep "129\."

      /opt/chrome-130/chrome --version | grep "130\."
      /opt/chromedriver-130/chromedriver --version | grep "130\."
```

# Using headless Chrome

By default, `google/install-chrome` supports tools that interact with Chrome in headless mode. Here's an example with Selenium and Ruby:

```yml
- key: chrome
  call: google/install-chrome 2.1.3
  with:
    chrome-version: stable
    install-chromedriver: true

- key: ruby
  call: mint/install-ruby 1.1.5
  with:
    ruby-version: 3.3.4

- key: selenium-example
  use: [chrome, ruby]
  run: |
    cat << EOF > Gemfile
    source "https://rubygems.org"

    gem "selenium-webdriver", "~> 4.24"
    EOF

    cat << EOF > selenium.rb
    require "selenium-webdriver"

    Selenium::WebDriver.logger.level = :debug
    Selenium::WebDriver.logger.output = 'selenium.log'

    options = Selenium::WebDriver::Options.chrome(args: ['--headless=new'])
    driver = Selenium::WebDriver.for(:chrome, options:)
    driver.navigate.to "http://google.com"

    element = driver.find_element(name: 'q')
    element.send_keys "Hello WebDriver!"
    element.submit

    puts driver.title

    driver.quit
    EOF

    bundle install

    ruby selenium.rb | grep "Hello WebDriver! - Google Search"
```

# Using headed Chrome

You can also use tools that interact with headed Chrome. To do so, wrap your command that interacts with Chrome with `xvfb-run`. `google/install-chrome` installs `xvfb` for you. Here's an example with Selenium and Ruby:

```yml
- key: chrome
  call: google/install-chrome 2.1.3
  with:
    chrome-version: stable
    install-chromedriver: true

- key: ruby
  call: mint/install-ruby 1.1.5
  with:
    ruby-version: 3.3.4

- key: selenium-example
  use: [chrome, ruby]
  run: |
    cat << EOF > Gemfile
    source "https://rubygems.org"

    gem "selenium-webdriver", "~> 4.24"
    EOF

    cat << EOF > selenium.rb
    require "selenium-webdriver"

    Selenium::WebDriver.logger.level = :debug
    Selenium::WebDriver.logger.output = 'selenium.log'

    options = Selenium::WebDriver::Options.chrome(args: [])
    driver = Selenium::WebDriver.for(:chrome, options:)
    driver.navigate.to "http://google.com"

    element = driver.find_element(name: 'q')
    element.send_keys "Hello WebDriver!"
    element.submit

    puts driver.title

    driver.quit
    EOF

    bundle install

    xvfb-run ruby selenium.rb | grep "Hello WebDriver! - Google Search"
```

Even though we make this available, we do recommend using headless mode whenever and wherever possible. `xvfb-run` is known to be flaky.
