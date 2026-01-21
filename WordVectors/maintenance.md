# Maintaining the Word Vector walkthroughs

## Where to work

Work should be done in the `WordVectors` branch. When you're done, test the changes, then create a pull request to merge your work directly into the `main` branch.

If you made any changes to the R walkthroughs, you should plan to update their HTML representations in the [Women Writers Vector Toolkit](https://github.com/NEU-DSG/women-writers-vector-toolkit) too. (Note that you don't need to worry about the "Model Training and Querying Template", which is more useful for coding than reading.)


## Creating an HTML version of an R walkthrough

1. Make sure your copy of WWVT is on the `proofing` branch.
2. Open the R walkthrough in RStudio.
2. In the file editor, find the button that says "Knit", below the filename.
3. Press the button. This will generate an HTML file in the same directory as the Rmd file.
4. In your file system manager (e.g. Finder), move the HTML file from the `WordVectors/` directory to the `resources/walkthroughs/` directory in the WWVT.
6. Open the `resources/walkthroughs/index.html` file in your browser (by double-clicking the file).
    1. Make sure you can navigate to the new or changed HTML file.
    2. Skim the walkthrough to make sure the output is readable and formatted correctly.
7. Commit your changes to the WWVT repository, and push the commit to GitHub.
8. Update the files on WWP Test for proofing.
    1. Log in.
    2. Navigate to the [wwp-test.northeastern.edu/lab/wwvt](https://wwp-test.northeastern.edu/lab/wwvt) folder.
    3. Run `sudo git pull`.
    4. Check the updated files.
9. [Create a pull request in the WWVT repository](https://github.com/NEU-DSG/women-writers-vector-toolkit/compare/main...NEU-DSG:women-writers-vector-toolkit:proofing), to merge the `proofing` branch into `main`.
    1. The link above will set up the pull request to go to the correct place.
    2. If you're creating a PR from the GitHub "Pull requests" page, make sure that the base repository is "NEU-DSG/women-writers-vector-toolkit" and the base branch is "main".
9. If the updates are substantial, consider getting someone to review your work. Otherwise, go ahead and merge the PR.
10. Update the files on the WWP's production server too.


## Creating a release

1. Merge the latest changes from `WordVectors` into `main`.
    1. Create a pull request on GitHub. Make sure the changes will be placed into the `main` branch from `WordVectors`.
    2. You may wish to have another person review the pull request before actually doing the merge.
        1. This could be helpful for proofing a new walkthrough before publication, for example.
        2. Mostly we're using pull requests here for record-keeping, so if the change is minor (updating links, etc.), you don't need to request a full review.
    3. When you and the WWP team are satisfied with the changes, merge the pull request.
2. On your computer, make sure you're on the `main` branch and you have all commits from GitHub.
    1. `git checkout main`
    2. `git pull`
3. Create an [annotated git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging#_creating_tags) for the last commit in this branch.
    1. The tag name should be "WordVectors/YYYY-MM-DD" (using the current date, or the date of the commit).
    2. The tag message should be a brief description of the PR's changes.
    3. For example: `git tag -a -m "Implement build process for ZIP releases" WordVectors/2026-01-21`
4. Push the tag to the GitHub repository.
    1. `git push --tags origin`
    2. Your new tag should now be listed on the repository's [Tags page](https://github.com/NEU-DSG/word-vector-interface/tags).
5. Create a ZIP of the codebase for customization, using an Apache Ant build.
    1. `cd WordVectors`
    2. `ant`
    3. You will be prompted for a versioning string. Use the date you chose for the tag name, e.g. `2026-01-21`.
    4. For the ZIP file for the R walkthroughs, you will be asked for the path to your copy of the [Word Vector Interface repository](https://github.com/NEU-DSG/word-vector-interface). This is used to bundle several models from the Shiny app into the ZIP file with the walkthroughs.
        1. You can get the path by opening a new terminal tab, navigating to the WVI directory, and using the `pwd` command.
        2. If the Ant build can't find the `wwo.bin` file at the path you pasted, the build will ZIP all the walkthroughs but not any models. It will also give you a command for re-running just the R ZIP process, with the correct path.
    3. (Optional.) Check the contents of the ZIP archives.
        1. Unzip each release.
        2. For the R ZIP, make sure there are models in the `data/` directory.
6. [Draft a release in GitHub.](https://github.com/NEU-DSG/word-vector-interface/releases/new)
    1. Select your new tag from the "Tag" dropdown.
    2. For the release title, use "WordVectors YYYY-MM-DD" (with the date you chose for the tag name).
    3. Write a short description of significant updates.
    4. Click the button that says "Attach binaries".
        1. Navigate to your ZIP files and select them.
    6. Make sure "Set as the latest release" is checked.
    7. Click the "Publish release" button.
6. Trumpet the achievement!

