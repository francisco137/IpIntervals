package pl.sao.iip.spark

import org.apache.spark.SparkConf
import org.apache.spark.sql.expressions.{UserDefinedFunction, Window}
import org.apache.spark.sql.functions._
import org.apache.spark.sql.{DataFrame, Dataset, SparkSession}
import org.elasticsearch.spark.sql.sparkDatasetFunctions
import pl.sao.iip.intervals.{Ip, IpIntervals, IpIntervalsLong}

trait SparkJob extends Serializable {

  private[this] val sparkConf: SparkConf = new SparkConf()
    .setAppName("IpSubRanges")
    .setMaster("local[*]")
    .set("es.nodes", "192.168.49.2")
    .set("es.port", "9200")
    .set("es.net.ssl","false")
    .set("es.nodes.wan.only", "true")
    .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
    .set("spark.es.index.auto.create", "true")
    .set("spark.es.resource", "test")
    .set("es.read.metadata", "true")

  val spark: SparkSession = SparkSession.builder()
      .config(sparkConf)
      .getOrCreate()

  val dataSet: Dataset[IpIntervalsLong]

  private[this] val udfMakeStringIp: UserDefinedFunction = udf((ipLong: Long ) => { Ip(ipLong).toString })

  import spark.implicits._
  def extractUniqueSubRanges: DataFrame = {
    val ranges = dataSet
      .flatMap(ip => List((ip.ipFr,1,0),(ip.ipTo,0,1)))
      .withColumn("ipLong",col("_1").cast("Long"))
      .withColumn("begins",col("_2").cast("Long"))
      .withColumn("ends",col("_3").cast("Long"))
      .withColumn("world",lit(1))
      .select($"world", $"ipLong", $"begins", $"ends")
      .groupBy("world","ipLong")
      .agg( sum("begins").as("begins"), sum(col("ends")).as("ends"))

    val windowSpec  = Window.partitionBy("world").orderBy("ipLong")
    ranges
      .withColumn("item",row_number.over(windowSpec))
      .withColumn("sum", sum(col("begins") - col("ends")).over(windowSpec))
      .withColumn("endIpLong", lag("ipLong",-1).over(windowSpec))
      .withColumn("sum_before", lag("sum",1).over(windowSpec))
      .withColumn("sum_after", lag("sum",-1).over(windowSpec))
      .filter( col("sum") === 0 && col("begins") === 1 && col("ends") === 1 || col("sum") === 1 )
      .withColumn("range_begin", udfMakeStringIp(col("ipLong") + when(col("sum_before") > 0, 1).otherwise(0)))
      .withColumn("range_end", udfMakeStringIp(col("endIpLong") - when(col("sum_after") > 0, 1).otherwise(0)))
      .select("range_begin", "range_end")
  }

  def saveToElasticSearch(subIntervalDataFrame: DataFrame): Unit = {
    val myIndex = "ipintervals/timestamp"
    subIntervalDataFrame
      .withColumn("timestamp", current_timestamp().cast("String"))
      .as[IpIntervals]
      .saveToEs(myIndex)
  }
}
