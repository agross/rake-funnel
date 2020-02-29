# 0.23.0 / 2020-02-29

* [FEATURE] Support rake < 14.

# 0.22.3 / 2019-01-08

* [BUGFIX] Support Ruby 2.6.0's ERB initializer.

# 0.22.2 / 2018-05-28

* [BUGFIX] Write output using atomic `print`.

# 0.22.1 / 2018-05-28

* [BUGFIX] Fix a bug with overridden methods from rake.

# 0.22.0 / 2018-05-05

* [FEATURE] Support [vswhere](https://github.com/Microsoft/vswhere) to locate
  MSBuild. It's advised to install vswhere as a NuGet package and add it to the
  `PATH`. You can use `Rake::Funnel::Tasks::BinPath` for that.
