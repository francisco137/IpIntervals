name := "Ip Intervals Project"
version := "0.1"
scalaVersion := "2.11.12"
organization := "pl.sao"

fork := true
lazy val makers = (project in file("."))
  .settings(
      libraryDependencies += "org.scalacheck"    %% "scalacheck"             % "1.15.2",
      libraryDependencies += "org.apache.spark"  %% "spark-sql"              % "2.4.7",
      libraryDependencies += "org.postgresql"    %  "postgresql"             % "42.2.14",
      libraryDependencies += "org.elasticsearch" %% "elasticsearch-spark-20" % "7.11.1",
)
