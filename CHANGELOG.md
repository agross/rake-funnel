# 0.22.0 / 2018-05-05

* [FEATURE] Support [vswhere](https://github.com/Microsoft/vswhere) to locate
  MSBuild. It's advised to install vswhere as a NuGet package and add it to the
  `PATH`. You can use `Rake::Funnel::Tasks::BinPath` for that.
