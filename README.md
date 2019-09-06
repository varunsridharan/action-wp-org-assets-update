> **⚠️ Note:** To use this GitHub Action, you must have access to GitHub Actions. GitHub Actions are currently only available in public beta. You can [apply for Github Actions beta access here](https://github.com/features/actions).

# WordPress.org Plugin Readme/Assets Update - ***Github Action***
This Action commits any `readme.txt` and WordPress.org-specific assets changes in your specified branch to the WordPress.org plugin repository if no other changes have been made since the last deployment to WordPress.org. This is useful for updating things like screenshots or `Tested up to` separately from functional changes, provided your Git branching methodology avoids changing anything else in the specified branch between functional releases. It is **highly recommended** that you use a stable branch where you only merge readme/asset commits in between larger functional merges that only occur when preparing for a release (often implemented as `master` vs. `develop`).

Because the WordPress.org plugin repository shows information from `readme.txt` in the specified `Stable tag`, this Action also attempts to parse out the stable tag from `readme.txt` and deploy to there as well as `trunk`. If your stable tag is `trunk` or a tag that does not exist in the `tags` subfolder, it will skip that part of the update and only update `trunk` and/or `assets`.

**Important note:** If your development process leads to a situation where `master` (or other specified branch) only contains changes to `readme.txt` or `assets` since the last sync to the plugin directory and those changes are in preparation for the next release, those changes will go live and potentially be misleading to users. Usage of this Action assumes a fairly traditional Git methodology that involves merging all changes to `master` when functional changes are ready and that this seemingly unlikely situation will therefore not happen in your repo; there are no safeguards against syncing changes based on readme/asset content, as that cannot be predicted.

### ☞ This Action is meant to be used in tandem with our [WordPress.org Plugin Deploy Action](https://github.com/varunsridharan/action-wp-org-deploy)

## Configuration
### Required secrets
* `WORDPRESS_USERNAME`
* `WORDPRESS_PASSWORD`
* `GITHUB_TOKEN` - you do not need to generate one but you do have to explicitly make it available to the Action

Secrets can be set while editing your workflow or in the repository settings. They cannot be viewed once stored. [GitHub secrets documentation](https://developer.github.com/actions/creating-workflows/storing-secrets/)

### Optional environment variables
* `SLUG` - defaults to the respository name, customizable in case your WordPress repository has a different slug. This should be a very rare case as WordPress assumes that the directory and initial plugin file have the same slug.
* `ASSETS_DIR` - defaults to `.wordpress-org`, customizable for other locations of WordPress.org plugin repository-specific assets that belong in the top-level `assets` directory (the one on the same level as `trunk`)
* `IGNORE_FILE` - defaults to `.wporgignore`, customizable for other locations of list of files to be ignore like `.gitignore`
* `ASSETS_IGNORE_FILE` - defaults to `.wporgassetsignore`, customizable for other locations of list of files to be ignore like `.gitignore`

### Excluding files from deployment
If there are files or directories to be excluded from deployment, such as tests or editor config files, they can be specified in your `.wporgignore` file. If you use this method, please be sure to include the following items:

```gitignore
# Directories
.wordpress-org
.github

# Files
/.gitattributes
/.gitignore
```

> **⚠️ Note:** You Should Provide Github Token. If Not No Updated File Will Be Committed & Pushed

## Example Workflow File
```yaml
name: Update WordPress.org
on:
  push:
    branches:
    - master
jobs:
  tag:
    name: Push To Readme OR WPAssets
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: WordPress.org plugin asset/readme update
      uses: varunsridharan/action-wp-org-assets-update@master
      with:
        WORDPRESS_PASSWORD: ${{ secrets.WORDPRESS_PASSWORD }}
        WORDPRESS_USERNAME: ${{ secrets.WORDPRESS_USERNAME }}
        SLUG: my-super-cool-plugin
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Credits
This Github Action Bootstrapped From 
* [10up/action-wordpress-plugin-asset-update](https://github.com/10up/action-wordpress-plugin-asset-update)  

---
## Change Log

### 1.0 - 06/09/2019
* First Release

## Contribute
If you would like to help, please take a look at the list of
[issues][issues] or the [To Do](#-todo) checklist.

## License
Our GitHub Actions are available for use and remix under the MIT license.

## Copyright
2017 - 2018 Varun Sridharan, [varunsridharan.in][website]

If you find it useful, let me know :wink:

You can contact me on [Twitter][twitter] or through my [email][email].

## Backed By
| [![DigitalOcean][do-image]][do-ref] | [![JetBrains][jb-image]][jb-ref] |  [![Tidio Chat][tidio-image]][tidio-ref] |
| --- | --- | --- |

[twitter]: https://twitter.com/varunsridharan2
[email]: mailto:varunsridharan23@gmail.com
[website]: https://varunsridharan.in
[issues]: issues/

[do-image]: https://vsp.ams3.cdn.digitaloceanspaces.com/cdn/DO_Logo_Horizontal_Blue-small.png
[jb-image]: https://vsp.ams3.cdn.digitaloceanspaces.com/cdn/phpstorm-small.png?v3
[tidio-image]: https://vsp.ams3.cdn.digitaloceanspaces.com/cdn/tidiochat-small.png
[do-ref]: https://s.svarun.in/Ef
[jb-ref]: https://www.jetbrains.com
[tidio-ref]: https://tidiochat.com

