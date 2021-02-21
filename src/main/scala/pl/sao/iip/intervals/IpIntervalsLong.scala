package pl.sao.iip.intervals

case class IpIntervalsLong(ipFr: Long, ipTo: Long) {

  require(ipFr <= ipTo, s"ipFr cannot be greater than ipTo: (ipFr=$ipFr > ipTo=$ipTo)")

  def makeString(prefix: String = "", divider: String = ",", suffix: String = ""): String =
    List(Ip(ipFr).toString, Ip(ipTo).toString).mkString(prefix, divider, suffix)
}
