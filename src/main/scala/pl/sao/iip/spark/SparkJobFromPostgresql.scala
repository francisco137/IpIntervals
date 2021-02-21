package pl.sao.iip.spark

import org.apache.spark.sql.Dataset
import org.apache.spark.sql.functions.{col, udf}
import pl.sao.iip.intervals.{Ip, IpIntervalsLong}

class SparkJobFromPostgresql(dbConf: Map[String,String]) extends SparkJob {

  private[this] val pgHost: String = dbConf("pgHost")
  private[this] val pgPort: String = dbConf("pgPort")
  private[this] val pgBase: String = dbConf("pgBase")
  private[this] val pgUser: String = dbConf("pgUser")
  private[this] val pgPass: String = dbConf("pgPass")

  private[this] val udfMakeLongIp = udf((ipString: String) => { Ip(ipString).ipLong })

  import spark.implicits._
  override val dataSet: Dataset[IpIntervalsLong] = spark.read.format("jdbc")
    .option("driver", "org.postgresql.Driver")
    .option("url", s"jdbc:postgresql://$pgHost:$pgPort/$pgBase?user=$pgUser&password=$pgPass")
    .option("user", pgUser)
    .option("password", pgPass)
    .option("dbtable", "ranges")
    .load()
    .withColumn("ipFr",udfMakeLongIp(col("ipFr")).cast("Long"))
    .withColumn("ipTo",udfMakeLongIp(col("ipTo")).cast("Long"))
    .filter(col("ipFr") <= col("ipTo"))
    .as[IpIntervalsLong]
}
