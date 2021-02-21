package pl.sao.iip.intervals

import crakjie.ipranges.v4.IP

case class Ip( ipLong: Long ) {
  private[this] val intAddress = (ipLong - {if (ipLong > 2147483648L) 2 * 2147483648L else 0}).toInt
  override def toString: String = IP(intAddress).toString
  IP(intAddress)
}
object Ip {

  val minIp: Long = 0L
  val maxIp: Long = 2 * 2147483648L - 1L

  def apply(ipStr: String): Ip = {
    val value = IP(ipStr).value
    Ip(value + { if ( value < 0 ) 2 * 2147483648L else 0 })
  }
}
