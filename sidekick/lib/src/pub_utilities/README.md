This folder contains some code from https://github.com/dart-lang/pub
which is needed by plugin_command.dart to install plugins more easily. 

The pub package is not published on the official package repository pub.dev
and only available on GitHub.

However, https://dart.dev/tools/pub/custom-package-repositories states:  
To ensure that public packages are usable to everyone, the official package repository, pub.dev, doesn’t allow publication of packages with git-dependencies or hosted-dependencies from custom package repositories.


TODO: Alternative -> publish sidekick_pub package containing the required modified pub code