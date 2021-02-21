package pl.sao.iip.postgres

import java.sql.{Connection, DriverManager, ResultSet, Statement}
import pl.sao.iip.intervals.IpIntervalsLong


case class IpIntervalPostgres(dbConf: Map[String,String]) {

	private[this] val pgHost: String = dbConf("pgHost")
	private[this] val pgPort: String = dbConf("pgPort")
	private[this] val pgBase: String = dbConf("pgBase")
	private[this] val pgUser: String = dbConf("pgUser")
	private[this] val pgPass: String = dbConf("pgPass")

	private[this] val url = s"jdbc:postgresql://$pgHost:$pgPort/$pgBase"

	private[this] val properties = new java.util.Properties
	properties.setProperty("user",pgUser)
	properties.setProperty("password",pgPass)

	private[this] val connection: Connection = DriverManager.getDriver(url).connect(url, properties)
	private[this] val statement: Statement = connection.createStatement()

	def delete: IpIntervalPostgres = {
		statement.executeUpdate("DELETE FROM ranges")
		this
	}

	def insert(rangesSeq: Seq[IpIntervalsLong]): IpIntervalPostgres = {
		connection.setAutoCommit(false)
		rangesSeq.foreach { range =>
			statement.executeUpdate(
				range.makeString("INSERT INTO ranges VALUES ('", "','", "');")
			)
		}
		connection.commit()
		connection.setAutoCommit(true)
		this
	}

	def select: Seq[(String, String)] = {
		var rangesSeq = scala.collection.mutable.Seq.empty[(String,String)]
		val sqlResult: ResultSet = statement.executeQuery("SELECT ipFr, ipTo FROM ranges ORDER BY ipFr, ipTo")
		while (sqlResult.next()) {
			rangesSeq :+= (sqlResult.getString(1),sqlResult.getString(2))
		}
		rangesSeq
	}
}