# Modules


## Repository Structure

``` sh
.
├── README.md
├── main.nf
└── modules
    └── UMCUGenetics
```

Modules are placed under the `./modules/UMCUGenetics/` folder in the format tool/subtool. For example `./modules/UMCUGenetics/samtools/view/`


## Linting configuration
Note: A fork of the nf-core CLI tools is used to run the linting actions (https://github.com/UMCUGenetics/nf-core-tools.git). This was done to make the linting of modules more customisable. For our purposes not all requirements by nf-core are neccesary.
Linting configuration of this repository is configured in `.nf-core.yml` and is structured similarly to how `nf-core pipeline lint` configuration works (note that the tests in the yaml file are the ones being skipped, all the others are enabled). Usually, it is not neccessary to change this, but to view all available modules linting options:

``` sh
nf-core modules lint --list
```

Install the forked nf-core tools locally:

``` sh
pip install git+https://github.com/UMCUGenetics/nf-core-tools.git
```

### Github actions
Linting is triggered automatically upon creating a pull request through a github actions workflow [.github/workflows/lint.yml]. The actions workflow is adapted from the actions workflow used in the [nf-core/modules](https://github.com/nf-core/modules) repository, with mostly small changes that remove nf-core specific action runners.

### Running linting

Alternatively, linting test can be manually executed:

``` sh
cd ./modules
nf-core modules lint <tool/command>
# Example: nf-core modules lint pgscatalog/combine
```



## Testing configuration
TODO


## Using a module in a nextflow pipeline
Modules in this repository can be added to a pipeline similarly to how nf-core modules are installed.

``` sh
nf-core modules --git-remote https://github.com/UMCUGenetics/Modules install pgscatalog/combine
```
