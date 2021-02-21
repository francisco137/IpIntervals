package pl.sao.iip.intervals

import java.io.{File, PrintWriter}
import org.scalacheck.Gen
import scala.annotation.tailrec

case class IpIntervalsGenerator(maxWidthRate: Double) {

  def generate(itemsNumber: Int, saveToFileName: String = ""): Seq[IpIntervalsLong] = {
    val rangesSeq = generate(Nil, itemsNumber)
    if (saveToFileName != "") saveToFile(rangesSeq, saveToFileName)
    rangesSeq
  }

  @tailrec
  private def generate(acc: Seq[IpIntervalsLong], itemsNumber: Int): Seq[IpIntervalsLong] = itemsNumber match {
    case i: Int if i <= 0 =>
      acc
    case _ =>
      val ip1 = Gen.choose[Long](Ip.minIp, Ip.maxIp).sample.get
      val ip2 = Math.min(Ip.maxIp, ip1 + Gen.choose[Long](0, (maxWidthRate * Ip.maxIp).toLong).sample.get)
      generate(acc :+ IpIntervalsLong(ip1, ip2), itemsNumber - 1)
  }

  private def saveToFile(rangesSeq: Seq[IpIntervalsLong], saveToFileName: String): Unit = {
    val pw = new PrintWriter(new File(saveToFileName))
    rangesSeq.foreach { range =>
      pw.write(range.makeString() + "\n")
    }
    pw.close()
  }

}
