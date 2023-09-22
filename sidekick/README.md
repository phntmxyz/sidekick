# What is sidekick?

Repetitive CLI tasks can be organized in many ways: READMEs, bash scripts, aliases, run configurations, CI/CD pipelines, etc.  
But all of these approaches have their drawbacks. Instead, a much better way is to create a CLI that is tailored to your project.

The sidekick CLI generator helps you do just that!

Advantages of a custom sidekick CLI for your project:
- Documentation of commands inside the CLI - no more outdated documentation as it is linked to the commands
- Easy language: write commands in Dart instead of complex Bash magic
- Testable/debuggable
- Scoped to project: only the commands you need
- CLI is shared through repo: easy to install and use for new team members

# Getting Started - Generating your own sidekick CLI for your project

Creating your own sidekick CLI is easy. Follow these simple steps to get started:

Make sure you have the `sidekick` CLI generator installed (this package).
```bash
dart pub global activate sidekick
```

Navigate to your project directory and run the following command to initialize a new sidekick CLI:
```bash
sidekick init
```

The CLI generator will guide you through the setup process. You will be prompted to provide some information (e.g. name of your CLI) and that's it!

You can now run your own sidekick CLI by calling it from the command line.

# Installing Sidekick CLI Globally and Enabling Tab Completions

To make your Sidekick CLI accessible from anywhere on your system and enable convenient tab completions, run the following command:
```bash
<your-cli-name> sidekick install-global
```

Now restart your terminal or resource your shell profile (e.g. `source ~/.bashrc` or `source ~/.zshrc`) and you can run your CLI from anywhere with tab completions.

# Available Default Commands and Plugins
The Sidekick CLI comes with a set of default commands to help you get started quickly. Additionally, it supports plugins that can be easily integrated to extend its functionality. Here's a list of some useful default commands and recommended plugins:

## Default Commands
These are only some of the commands available in a freshly generated sidekick CLI:
`deps`: Gets dependencies for all packages (including nested packages)
`format`: Formats all Dart files in all packages (including nested packages)
`sidekick create-command`: Creates a template for a new command and adds it to your CLI
`sidekick plugins create`: Create a new sidekick plugin from some templates
`sidekick plugins install`: Install a sidekick plugin to your CLI (from pub.dev/Github/local path)

## Recommended Plugins
Enhance your Sidekick CLI with these recommended plugins:

[`sidekick_vault`](https://pub.dev/packages/sidekick_vault): Stores secrets within the project’s git repository, encrypted with GPG
[`dockerize_sidekick_plugin`](https://pub.dev/packages/dockerize_sidekick_plugin): Makes it easy to deploy your flutter web app as a docker container
[`flutterw_sidekick_plugin`](https://pub.dev/packages/flutterw_sidekick_plugin): Pins Flutter SDK to exact version defined per project
[`phntmxyz_bump_version_sidekick_plugin`](https://pub.dev/packages/phntmxyz_bump_version_sidekick_plugin): Adds command to bump the version of a package

You can find all available sidekick plugins on pub.dev [here](https://pub.dev/packages?q=topic%3Asidekick-plugin).

All other packages related to sidekick on pub.dev can be found [here](https://pub.dev/packages?q=topic%3Asidekick).

Install plugins to your cli with `<your-cli-name> sidekick plugins install <plugin-name>`

# Learn More About Sidekick
If you're interested in delving deeper into Sidekick and discovering advanced tips and techniques, consider watching our comprehensive talk:
- [Video](https://www.droidcon.com/2023/08/07/automating-cli-workflows-with-sidekick-customizable-debuggable-and-efficient/)
- [Slides](https://docs.google.com/presentation/d/1_NkDHcqE4Tw8M_mCcQozSRn_x4tY5SiRZNbKe_ZejW8)


# License

```text
Copyright 2023 phntm GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
