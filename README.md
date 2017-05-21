# Catch 4 Ceedling
Ceedling plugin replacing the integrated Unity framework with Catch

## Warning: This is a work in progress
* Reporting does not really work!
* Catch will not register failing mocks!

## Preconditions:
[HappyMapper](https://github.com/dam5s/happymapper) has to be installed

## Enabling plugin
Add `- Catch_4_Ceedling` to the :plugins:enabled: section in your project.yml

## Mocking
CMocks validate method has to be called manually in testcase.
Alternatively use fff plugin
