package pl.sao.iip

import pl.sao.iip.postgres.IpIntervalPostgres
import pl.sao.iip.spark.{SparkJobFromFile, SparkJobFromPostgresql, SparkJobFromSequence}
import pl.sao.iip.intervals.{IpIntervalsLong, IpIntervalsGenerator}

object IpIntervalsProject extends Serializable {

  def main(args: Array[String]): Unit = {
    val APP_NAME   = "IpIntervals"
    val APP_VERS   = "0.1"
    val APP_OWNER  = "Waldemar C. Biernacki"
    val APP_RIGHTS = "All rights reserved"

    println("===================================================================================")
    println(s" This is $APP_NAME ver.$APP_VERS (C) $APP_OWNER, 2021, $APP_RIGHTS")
    println("-----------------------------------------------------------------------------------")
    println(" ")

    val minikubeIp = { if ( args.nonEmpty ) args.head else "localhost" }
    println(s"Minikube declared at IP address '$minikubeIp'")
    println(" ")

    val appConfig = Map(
      "pgHost"-> minikubeIp ,
      "pgPort"-> "5432",
      "pgBase" -> "francisco",
      "pgUser" -> "root",
      "pgPass" -> "root",
      "spark.es.nodes" -> minikubeIp,
      "spark.es.port" -> "9200"
    )

    val rangesNumber: Int = 100
    require(rangesNumber > 0, "rangesNumber must be positive")

    val maxWidthRate: Double = 1D / Math.sqrt(rangesNumber)
    require(0 <= maxWidthRate && maxWidthRate <= 1, "maxWidthRate must be in the interval [0,1] - ends included")

    println("Generating IP ranges sequence, please wait...")
    val saveToFileName = "ranges.csv"
    val rangesSeq: Seq[IpIntervalsLong] = IpIntervalsGenerator(maxWidthRate).generate(rangesNumber, saveToFileName)
    println(s"    The ranges sequence was written in the file named '$saveToFileName'")
    println(" ")

    println("Connecting to Postgres")
    val pg = IpIntervalPostgres(appConfig)
    println("    Deleting old ranges sequence from database, please wait...")
    pg.delete
    println("    Inserting new ranges sequence into database, please wait...")
    pg.insert(rangesSeq)
    println(" ")

    println("Searching unique sub-ranges taking data from the ranges sequence, please wait...")
    val extractJobFromSequence = new SparkJobFromSequence(rangesSeq).extractUniqueSubRanges
    extractJobFromSequence.show()
    println(" ")

    println(s"Searching unique sub-ranges taking data from file '$saveToFileName', please wait...")
    val extractJobFromFile = new SparkJobFromFile(saveToFileName).extractUniqueSubRanges
    extractJobFromFile.show()
    println(" ")

    println("Searching unique sub-ranges taking data from the postgres, please wait...")
    val job = new SparkJobFromPostgresql(appConfig)
    val extractJobFromPostgresql = job.extractUniqueSubRanges
    extractJobFromPostgresql.show()
    println(" ")

    println("Saving the postgres result in Elasticsearch, please wait...")
    job.saveToElasticSearch(extractJobFromPostgresql)
    println(" ")
    println("__END__")
  }
}

