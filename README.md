# Catch-4-Ceedling
Ceedling plugin replacing the integrated Unity framework with Catch

## Enabling plugin
Add `- Catch_4_Ceedling` to the :plugins:enabled: section in your project.yml

## Compiling
Set flags for `-x c++` or change the compiler executable

## Linking
Set the linker to C++ & add stl
    :test_linker:
        :executable: g++
        :name: 'GCC Linker'
        :arguments:
            - ${1}               #list of object files to link (Ruby method call param list sub)
            - -o ${2}

## Mocking
CMocks validate method has to be called manually in testcase.
Alternatively use fff plugin