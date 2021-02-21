package pl.sao.iip.spark

import org.apache.spark.sql.Dataset
import org.apache.spark.sql.functions.{col, udf}
import org.apache.spark.sql.types.{StringType, StructField, StructType}
import pl.sao.iip.intervals.{Ip, IpIntervalsLong}


class SparkJobFromFile(fromFile: String) extends SparkJob {
  private val udfMakeLongIp = udf((ipString: String) => { Ip(ipString).ipLong })
  private val ipRangeSchema = StructType(Array(
    StructField("ipFr",StringType,nullable = false),
    StructField("ipTo",StringType,nullable = false)
  ))

  import spark.implicits._
  override val dataSet: Dataset[IpIntervalsLong] = spark
    .read.format("csv").schema(ipRangeSchema)
    .load(fromFile)
    .withColumn("ipFr",udfMakeLongIp(col("ipFr")).cast("Long"))
    .withColumn("ipTo",udfMakeLongIp(col("ipTo")).cast("Long"))
    .filter(col("ipFr") <= col("ipTo"))
    .as[IpIntervalsLong]
}
