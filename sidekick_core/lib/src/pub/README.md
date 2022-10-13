This folder contains code from https://github.com/dart-lang/pub needed by plugin_command.dart to install plugins. 

The pub package is not published on the official package repository pub.dev and only available on GitHub.

However, https://dart.dev/tools/pub/custom-package-repositories states:  
To ensure that public packages are usable to everyone, the official package repository, pub.dev, 
doesn’t allow publication of packages with git-dependencies or hosted-dependencies from custom package repositories.

Therefore, the needed code needs can't be added as a pub.dev dependency or git dependency and is copied here instead.

Alternatives:
- open a PR for pub to expose the information needed by plugin_command.dart directly (so internal code isn't needed anymore)
- publish a sidekick_pub package containing the required modified pub code and depend on it
