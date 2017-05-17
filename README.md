# Catch 4 Ceedling
Ceedling plugin replacing the integrated Unity framework with Catch

## Warning: This is a work in progress and does not function (at all!)

## Enabling plugin
Add `- Catch_4_Ceedling` to the :plugins:enabled: section in your project.yml

## Mocking
CMocks validate method has to be called manually in testcase.
Alternatively use fff plugin


## Tasks
- [x] Overwrite Unity test runner generator
- [x] Include initialization of generated mocks
- [x] Set flags for compiler automatically
- [x] Set flags for linker automatically
- [x] Override Test Preprocessor, which cannot preprocess catch.hpp
- [ ] Link Catch main file separately to improve compilation speed
- [ ] Use proper plugin interfaces instead of monkey patching
- [ ] Create Catch reporter, so that Ceedling will comprehend the output
