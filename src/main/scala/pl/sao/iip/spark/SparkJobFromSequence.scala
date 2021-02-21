package pl.sao.iip.spark

import org.apache.spark.sql.Dataset
import pl.sao.iip.intervals.IpIntervalsLong

class SparkJobFromSequence(ipRanges: Seq[IpIntervalsLong]) extends SparkJob {
  import spark.implicits._
  override val dataSet: Dataset[IpIntervalsLong] = spark
    .createDataset(ipRanges)
}
