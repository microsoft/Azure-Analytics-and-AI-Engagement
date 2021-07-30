// Databricks notebook source
// MAGIC %md
// MAGIC **DISCLAIMER**
// MAGIC 
// MAGIC By accessing this code, you acknowledge the code is made available for presentation and demonstration purposes only and that the code (1) is not subject to SOC 1 and SOC 2 compliance audits, and (2) is not designed or intended to be a substitute for the professional advice, diagnosis, treatment, or judgment of a certified financial services professional. Do not use this code to replace, substitute, or provide professional financial advice, or judgement. You are solely responsible for ensuring the regulatory, legal, and/or contractual compliance of any use of the code, including obtaining any authorizations or consents, and any solution you choose to build that incorporates this code in whole or in part.

// COMMAND ----------

// MAGIC %md
// MAGIC # ESG - data driven ESG score
// MAGIC 
// MAGIC The future of finance goes hand in hand with social responsibility, environmental stewardship and corporate ethics. In order to stay competitive, Financial Services Institutions (FSI)  are increasingly  disclosing more information about their **environmental, social and governance** (ESG) performance. By better understanding and quantifying the sustainability and societal impact of any investment in a company or business, FSIs can mitigate reputation risk and maintain the trust with both their clients and shareholders. At Databricks, we increasingly hear from our customers that ESG has become a C-suite priority. This is not solely driven by altruism but also by economics: [Higher ESG ratings are generally positively correlated with valuation and profitability while negatively correlated with volatility](https://corpgov.law.harvard.edu/2020/01/14/esg-matters/). In this demo, we offer a novel approach to sustainable finance by combining NLP techniques and graph analytics to extract key strategic ESG initiatives and learn companies' relationships in a global market and their impact to market risk calculations.
// MAGIC 
// MAGIC ---
// MAGIC + <a href="https://databricks.com/notebooks/esg_notebooks/01_esg_report.html">STAGE1</a>: Using NLP to extract key ESG initiatives PDF reports
// MAGIC + <a href="https://databricks.com/notebooks/esg_notebooks/02_esg_scoring.html">STAGE2</a>: Introducing a novel approach to ESG scoring using graph analytics
// MAGIC + <a href="https://databricks.com/notebooks/esg_notebooks/03_esg_market.html">STAGE3</a>: Applying ESG to market risk calculations
// MAGIC ---

// COMMAND ----------

// MAGIC %md
// MAGIC ## Context
// MAGIC As covered in the previous notebook (see <a href="https://databricks.com/notebooks/01_esg_report.html">STAGE1</a>), we were able to compare businesses side by side across 9 different ESG initiatives. Although we could attempt to derive an ESG score (the approach many third party organisations would use), we want our score not to be subjective but truly data driven. For that purpose, we use [GDELT](https://www.gdeltproject.org/), the global database of event location and tones. [...] *Supported by Google Jigsaw, the GDELT Project monitors the world's broadcast, print, and web news from nearly every corner of every country in over 100 languages and identifies the people, locations, organizations, themes, sources, emotions, counts, quotes, images and events driving our global society every second of every day, creating a free open platform for computing on the entire world.*
// MAGIC 
// MAGIC In this section, we want to compute a data driven and fact based ESG score (as opposition to what a company disclose as part of their yearly report). Therefore, it is key not to derive a sentiment analysis for each company itself but rather to learn the connections among them by the number of news articles they share. When looking at this problem from a network perspective, the "true" ESG score should be derived from the contribution of a company's connections. As an example, if a firm keeps investing in companies directly or indirectly related with environmental issues (and as such mentioned in negative tone articles), this should  - and must - be reflected back on companies' overall ESG. Augmented with your internal data, this approach will capture patterns you can use to mitigate your ESG related risks. See an example with Barclays reputation being impacted because of its indirect connections to tar sand projects ([source](https://www.theguardian.com/business/2018/dec/05/barclays-customers-threaten-leave-en-masse-tar-sands-investment-greenpeace)). 
// MAGIC 
// MAGIC [Page Rank](https://en.wikipedia.org/wiki/PageRank) is a common technique used to identify nodes importance in large network. Democratized for web indexing, it can be applied in various setup to detect influential nodes. In this example, we use a variant of Page Rank, **Personalised Page Rank**, where we want to identify influencial nodes relative to our core companies we would like to score. As "influencer" nodes, these important connections will strongly contribute to an ESG coverage for a given organisation. 
// MAGIC 
// MAGIC ### Dependencies
// MAGIC 
// MAGIC As reported in below cell, we use multiple 3rd party libraries that must be made available across Spark cluster. Assuming you are running this notebook on a Databricks cluster that does not make use of the ML runtime, you can use `dbutils.library.installPyPI()` utility to install python libraries in that specific notebook context. For java based libraries, or if you are using an ML runtime, please follow these [alternative steps](https://docs.databricks.com/libraries.html#workspace-library) to load libraries to your environment. 
// MAGIC 
// MAGIC In order to efficiently process GDELT files, we make use of an open source scala based library I personally open sourced as a pet project (`com.aamend.spark:spark-gdelt:2.x`). Note that it does not represent Databricks in any way as this was developed a long time ago and maintained on a best effort basis. In addition, we also bring `graphframes:graphframes:0.6.0-spark2.3-s_2.11` as an abstraction layer to core `graphx` functionality.

// COMMAND ----------

// DBTITLE 1,Install needed libraries
// MAGIC %python
// MAGIC dbutils.library.installPyPI('wordcloud')
// MAGIC dbutils.library.installPyPI('pandas', '0.24.2')
// MAGIC dbutils.library.installPyPI('matplotlib', '3.0.3')
// MAGIC dbutils.library.restartPython()

// COMMAND ----------

// MAGIC %md
// MAGIC ## `STEP1`: Download RAW gdelt files
// MAGIC GDELT files are published every 15mn. Although it is convenient to scrape for [master URL]((http://data.gdeltproject.org/gdeltv2/lastupdate.txt) file to process latest GDELT increment, processing 2 years backlog is time consuming and resource intensive. Below bash script is for illustration purpose mainly, so please proceed with caution. 

// COMMAND ----------

try {
  dbutils.fs.rm("/tmp/gdelt", true)
} finally {
  dbutils.fs.mkdirs("/tmp/gdelt")
}

// COMMAND ----------

// DBTITLE 1,Download 2021 data - CAUTION (long process)
// MAGIC %sh
// MAGIC 
// MAGIC MASTER_URL=http://data.gdeltproject.org/gdeltv2/masterfilelist.txt
// MAGIC 
// MAGIC if [[ -e /tmp/gdelt ]] ; then
// MAGIC   rm -rf /tmp/gdelt
// MAGIC fi
// MAGIC mkdir /tmp/gdelt
// MAGIC 
// MAGIC echo "Retrieve 2021 archives to date"
// MAGIC URLS=`curl ${MASTER_URL} 2>/dev/null | awk '{print $3}' | grep gkg.csv.zip | grep gdeltv2/2021`
// MAGIC for URL in $URLS; do
// MAGIC   echo "Downloading ${URL}"
// MAGIC   wget $URL -O /tmp/gdelt/gdelt.csv.zip > /dev/null 2>&1
// MAGIC   unzip /tmp/gdelt/gdelt.csv.zip -d /tmp/gdelt/ > /dev/null 2>&1
// MAGIC   LATEST_FILE=`ls -1rt /tmp/gdelt/*.csv | head -1`
// MAGIC   LATEST_NAME=`basename ${LATEST_FILE}`
// MAGIC   cp $LATEST_FILE /dbfs/tmp/gdelt/$LATEST_NAME
// MAGIC   rm -rf /tmp/gdelt/gdelt.csv.zip
// MAGIC   rm $LATEST_FILE
// MAGIC done

// COMMAND ----------

// MAGIC %fs ls /tmp/gdelt

// COMMAND ----------

// DBTITLE 1,Parse GDELT events using 3rd party library
import com.aamend.spark.gdelt._
val gdeltDF = spark.read.gdeltGkgV2("/tmp/gdelt")
//Commenting to avoid re-run
// gdeltDF.write.format("delta").mode("append").saveAsTable("esg_db.gdelt")


// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT publishDate FROM esg_db.gdelt where publishDate BETWEEN'2019-12-01T00:00:00.000+0000' AND '2019-12-31T23:45:00.000+0000'

// COMMAND ----------

// MAGIC %sql
// MAGIC Select COUNT(*) from esg_db.gdelt
// MAGIC 
// MAGIC -- Data till March 2021  from Jan 2020  is 65526541

// COMMAND ----------

// MAGIC %md
// MAGIC GDELT dataset is "fairly" big, with over 80 million records for the last 18 months worth of data.

// COMMAND ----------

// DBTITLE 1,GDELT timeline
// MAGIC %sql
// MAGIC SELECT to_date(publishDate) AS date, COUNT(*)
// MAGIC FROM esg_db.gdelt
// MAGIC GROUP BY date
// MAGIC ORDER BY date ASC

// COMMAND ----------

// MAGIC %md
// MAGIC Our Delta Lake table may be composed of many small files (one per 15mn window at least). To improve the performance of queries, we run the `OPTIMIZE` command as follows

// COMMAND ----------

// DBTITLE 1,Compact small files
// MAGIC %sql
// MAGIC OPTIMIZE esg_db.gdelt

// COMMAND ----------

// MAGIC %md
// MAGIC ## `STEP2`: extract relevant records for ESG
// MAGIC Whilst GDELT captures over 2000+ themes (keywords based), we want to focus only on specific themes to our problem statement and filter for ESG related articles to a silver table.
// MAGIC 
// MAGIC - We assume all `ENV_*` themes to be related to **environment**
// MAGIC - We assume all `UNGP_*` themes to be related to **social** ([United nations guiding principles for human right](https://en.wikipedia.org/wiki/United_Nations_Guiding_Principles_on_Business_and_Human_Rights))
// MAGIC - Any other financial news (captured via `ECON_*`) would affect the company **governance** and conduct strategy.

// COMMAND ----------

// DBTITLE 1,Dedupe FSI records
import org.apache.spark.sql.functions._

// Organisations may be called slightly differently, so we want to retrieve our ESG specific records using alternative names
val organisationAltNames = Map(
  "standard chartered"       -> Seq("standard chartered"),
  "rbc"                      -> Seq("rbc ", "royal bank of canada"),
  "credit suisse"            -> Seq("credit suisse"),
  "lloyds"                   -> Seq("lloyds bank"),
  "jp morgan chase"          -> Seq("jpmorgan", "jp morgan"),
  "goldman sachs"            -> Seq("goldman sachs"),
  "santander"                -> Seq("santander", "banco santander"),
  "lazard"                   -> Seq("lazard"),
  "macquarie"                -> Seq("macquarie group", "macquarie bank", "macquarie management", "macquarie investment", "macquarie capital"),
  "barclays"                 -> Seq("barclays"),
  "northern trust"           -> Seq("northern trust"),
  "citi"                     -> Seq("citigroup"),
  "morgan stanley"           -> Seq("morgan stanley")
)

// Broadcast of dictionay of names
val organisationAltNamesB = spark.sparkContext.broadcast(organisationAltNames)

// Clean organisation name. If match our ESG list, get the clean name, else, return the original organisation name
val cleanOrganisation = udf((s: String) => {
  organisationAltNamesB.value.find({ case (organisation, alts) =>
    alts.exists(alt => {
      s.startsWith(alt)
    })
  }).map(_._1).getOrElse(s)
})

// COMMAND ----------

// MAGIC %md
// MAGIC Given the volume of data available in GDELT (100 million records for the last 18 months only), we leverage the [lakehouse](https://databricks.com/blog/2020/01/30/what-is-a-data-lakehouse.html) paradigm by moving data from raw, to filtered and enriched, respectively from Bronze, to Silver and Gold layers, and extend our process to operate in near real time

// COMMAND ----------

// DBTITLE 1,User defined functions
import org.apache.spark.sql.functions._
import org.apache.spark.sql.Row

// Only search for ECON, ENV or UNGP related themes
// We assume all ENV_ themes to be related to environment
// We assume all UNGP_ themes to be related to social (United nations guiding principles for human right)
// Any other financial news (captured via ECON_) would affect the company governance and conduct strategy.
val filterThemes = udf((xs: Seq[String]) => {
  val themes = xs.flatMap(x => {
    x.split("_").head match {
      case "ENV"  => Some("E")
      case "ECON" => Some("G")
      case "UNGP" => Some("S")
      case _      => None: Option[String]
    }
  })
  // Any article, regardless of Environmental or Social would need to be ECON_ related to be used in that demo
  if(themes.exists(theme => theme == "G"))
    themes.distinct
  else
    Seq.empty[String]
})

// COMMAND ----------

// DBTITLE 1,Process GDELT increment to silver table

import com.aamend.spark.gdelt._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

val gdeltStreamDf = spark
  .readStream                                                   // Reading as a stream, processing record since last check point
  .format("delta")                                              // Reading from a delta table
  .table("esg_db.gdelt")                                           // Bronze table to read data from, then enrich and filter
  .withColumn("themes", filterThemes(col("themes")))
  .filter(size(col("themes")) > 0)
  .withColumn("organisation", explode(col("organisations")))
  .withColumn("organisation", cleanOrganisation(lower(col("organisation"))))
  .select(
    col("publishDate"),
    col("organisation"),
    col("documentIdentifier").as("url"),
    col("themes"),
    col("tone.tone")
  )

gdeltStreamDf
  .writeStream                                                   // Writing data as a stream
  .trigger(Trigger.Once)                                         // Create a streaming job triggered only once...
  .option("checkpointLocation", "/tmp/gdelt_esg_3")              //... that only processes data since last checkpoint
  .format("delta")                                               // write to delta table
  .table("esg_db.gdelt_silver")                                     // write enriched / cleansed data to silver layer



// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT to_date(publishDate) AS date, COUNT(*)
// MAGIC FROM esg_db.gdelt_silver
// MAGIC GROUP BY date
// MAGIC ORDER BY date ASC

// COMMAND ----------

// DBTITLE 1,Financial news for Goldman Sachs
// MAGIC %sql
// MAGIC SELECT publishDate, url, themes, tone FROM esg_db.gdelt_silver
// MAGIC WHERE organisation = 'barclays'

// COMMAND ----------

// MAGIC %md
// MAGIC ## `STEP3`: Create aggregated view for organisations
// MAGIC We want to use GDELT as a proxy for ESG scoring, looking at sentiment analysis (captured by native GDELT with no need to create our own NLP pipeline) across different themes of interest. We will be aggregating sentiment across themes and organisations for each of our the companies we captured in previous notebook (companies for which we have an existing ESG report).

// COMMAND ----------

// DBTITLE 1,Create aggregated view by theme
// MAGIC %sql
// MAGIC 
// MAGIC -- aggregate sentiment, count by themes for each organisation
// MAGIC -- we prefer SUM of sentiment over AVG so that the average can still be computed for different slices of data
// MAGIC CREATE TABLE esg_db.gdelt_gold USING delta AS
// MAGIC SELECT 
// MAGIC   u.date,
// MAGIC   u.organisation,
// MAGIC   u.theme,
// MAGIC   SUM(u.tone) AS tone,
// MAGIC   COUNT(*) AS total
// MAGIC FROM (
// MAGIC   SELECT 
// MAGIC     to_date(g.publishDate) AS date,
// MAGIC     g.organisation,
// MAGIC     explode(g.themes) AS theme,
// MAGIC     g.tone
// MAGIC   FROM esg_db.gdelt_silver g
// MAGIC   WHERE length(g.organisation) > 0
// MAGIC ) u
// MAGIC GROUP BY
// MAGIC   u.date,
// MAGIC   u.organisation,
// MAGIC   u.theme;
// MAGIC 
// MAGIC -- display table
// MAGIC SELECT * FROM esg_db.gdelt_gold;

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT * FROM esg_db.gdelt_gold;

// COMMAND ----------

// MAGIC %md
// MAGIC ## `STEP4`: Create an internal ESG score
// MAGIC Our simple approach is to look at the difference between a company sentiment and its industry average; how much more "positive" or "negative" a company is perceived across all financial services news articles. By looking at the average of that difference over day, and normalizing across industries, we create a score internal to a company across its 'E', 'S' and 'G' dimensions. We will later understand the companies connections to normalize this score by the contribution of its connected components (mentioned in introduction as influential nodes).

// COMMAND ----------

// DBTITLE 1,Create industry average
// MAGIC %python
// MAGIC from pyspark.sql import functions as F
// MAGIC 
// MAGIC # access sentiment across all companies mentioned in financial news
// MAGIC # as our table was using SUM(tone) instead of AVG(tone), we can easily access the average accross the E, S and G
// MAGIC industry_avg = spark \
// MAGIC   .read \
// MAGIC   .table('esg_db.gdelt_gold') \
// MAGIC   .groupBy('date') \
// MAGIC   .agg(
// MAGIC     F.sum("tone").alias("tone"),
// MAGIC     F.sum("total").alias("total")
// MAGIC   ) \
// MAGIC   .withColumn("tone", F.col("tone") / F.col("total")) \
// MAGIC   .select('date', 'tone') \
// MAGIC   .toPandas() \
// MAGIC   .sort_values('date') \
// MAGIC   .set_index('date') \
// MAGIC   .asfreq(freq = 'D', method = 'pad')
// MAGIC print(industry_avg)

// COMMAND ----------

// MAGIC %sql
// MAGIC Select * from esg_db.gdelt_gold where organisation = 'blackrock'

// COMMAND ----------

// MAGIC %sql
// MAGIC Select distinct organisation from esg_db.gdelt_gold

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT * FROM esg_db.gdelt_gold WHERE organisation like '%hsbc bank%'

// COMMAND ----------

// DBTITLE 1,Sentiment of Woodgrove compare to industry average
// MAGIC %python
// MAGIC import pandas as pd
// MAGIC from pyspark.sql import functions as F
// MAGIC import matplotlib.pyplot as plt
// MAGIC # from pandas.plotting import register_matplotlib_converters
// MAGIC # register_matplotlib_converters()
// MAGIC # retrieve Barclays average sentiments across its E, S and G news articles
// MAGIC # we convert as a timeseries to Pandas for visualisation
// MAGIC companyName = "Woodgrove"
// MAGIC barclays_df = spark \
// MAGIC   .read \
// MAGIC   .table('esg_db.gdelt_gold') \
// MAGIC   .filter(F.col('organisation') == companyName) \
// MAGIC   .groupBy('date', 'organisation') \
// MAGIC   .agg(
// MAGIC     F.sum("tone").alias("tone"),
// MAGIC     F.sum("total").alias("total")
// MAGIC   ) \
// MAGIC   .withColumn("tone", F.col("tone") / F.col("total")) \
// MAGIC   .select('date', 'tone') \
// MAGIC   .toPandas() \
// MAGIC   .sort_values('date') \
// MAGIC   .set_index('date') \
// MAGIC   .asfreq(freq = 'D', method = 'pad')
// MAGIC # print(barclays_df)
// MAGIC # we can join Citi series with industry average
// MAGIC # and compute daily difference (being positive or negative)
// MAGIC diff_df = industry_avg.merge(barclays_df, left_index=True, right_index=True)
// MAGIC 
// MAGIC diff_df['delta'] = diff_df['tone_y'] - diff_df['tone_x']
// MAGIC diff_df.head()
// MAGIC # visualize Citi diff compare to industry average
// MAGIC fig = plt.figure(figsize=(20,10))
// MAGIC 
// MAGIC # plot raw data as well as 7 days moving average for better interpretation
// MAGIC plt.plot(diff_df.index, diff_df.delta, color='lightblue', label='')
// MAGIC plt.plot(diff_df.index, diff_df.rolling(window=7).mean().delta, color='dodgerblue', label='sentiment benchmark')
// MAGIC plt.legend(loc='upper left', frameon=False)
// MAGIC plt.axhline(0, linewidth=.5, color='grey')
// MAGIC 
// MAGIC display(fig)
// MAGIC #display(barclays_df)
// MAGIC #print(diff_df.rolling(window=7).mean().delta)

// COMMAND ----------

// MAGIC %md
// MAGIC With a (un-normalised) score of 0.9 (average of daily difference), Barclays positively deviate from the industry by +0.9 in average, indicative of good ESG score

// COMMAND ----------

// DBTITLE 1,Migrating Organization Sentiment VS Industry Average Raw Data to Synapse
// MAGIC %python
// MAGIC #Saving required dataframe data to intermediary source table
// MAGIC 
// MAGIC org_df = diff_df
// MAGIC org_df['7dayrolling'] = diff_df.rolling(window=7).mean().delta
// MAGIC org_df['organisation'] = companyName
// MAGIC org_df = org_df[['organisation','delta','7dayrolling']]
// MAGIC 
// MAGIC #reset index to get date column 
// MAGIC org_df.reset_index(inplace= True)
// MAGIC org_df = spark.createDataFrame(org_df)
// MAGIC #org_df.withColumn("organisation", F.col(companyName))
// MAGIC 
// MAGIC org_df \
// MAGIC .write.mode("append") \
// MAGIC .format("delta") \
// MAGIC .saveAsTable("esg_db.srcEsgOrgSentiment")

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT DISTINCT Organisation FROM esg_db.srcEsgOrgSentiment

// COMMAND ----------

// DBTITLE 1,Intermediary Transfer
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

//read data from source table
//create a streaming dataframe to store data in an intermediate table
val streamDf = spark 
  .readStream                                                  // Reading as a stream, processing record since last check point
  .format("delta")                                            // Reading from a delta table  
  .table("esg_db.srcEsgOrgSentiment")  //Main source table
  .withColumn("IsMigrated", lit(0)) 

//Create a chekpoint of last insertion
//checkpoint makes sure that the only the changes in the source data, if any, will be stored in intermediate data
streamDf
  .writeStream                                                                  // Writing data as a stream
  .trigger(Trigger.Once)                                                       // Create a streaming job triggered only once...
  .option("checkpointLocation", "/esg_checkpoint/dbrEsgOrgSentiment_5") //Don't change checkpoint location (processes data since last checkpoint)
  .format("delta")                                                              // write to delta table
  .table("esg_db.dbrEsgOrgSentiment")   //Save to intermediary Databricks table

// COMMAND ----------

// DBTITLE 1,To Synapse
// //Configuration settings to connect to blob storage
//spark.conf.set("fs.azure.account.key.#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net","#STORAGE_ACCOUNT_KEY#"))


//declaring the credentials
//val sqluser =  dbutils.secrets.get(scope="esgmigratecreds", key="sqluser")
//val sqlpassword = dbutils.secrets.get(scope="esgmigratecreds", key="sqlpassword")
//val dbtable = "ADB_EsgOrgSentiment" //Synapse Table Name Set here
//val url = s"jdbc:sqlserver://#WORKSPACE_NAME#.sql.azuresynapse.net:1433;database=#DATABASE_NAME#;user=#SQL_USERNAME#;password=#SQL_PASSWORD#;encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.sql.azuresynapse.net;loginTimeout=30;authentication=ActiveDirectoryPassword"

// //Read only newer records from our intermediary table in Databricks
// var migrate_df = spark.sql("SELECT Date, Organisation, Delta, 7DayRolling, current_timestamp() as ReportedOn FROM esg_db.dbrEsgOrgSentiment WHERE IsMigrated = 0")
 
// print(s"Total Records", migrate_df.count())
// print("\n")

// //Send new records to synapse for further processing
// migrate_df.write.format("com.databricks.spark.sqldw").option("forwardSparkAzureStorageCredentials", "true").mode("append").option("url", url).option("dbtable", dbtable).option("tempDir", "abfss://esg-migrate@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/tempDirs").save()

// //Mark records as migrated after successfully saved to synapase
// spark.sql("UPDATE esg_db.dbrEsgOrgSentiment SET IsMigrated = 1 WHERE IsMigrated = 0")

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT MAX(total) FROM esg_db.gdelt_gold;

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT * FROM esg_db.gdelt_gold WHERE Organisation like 'hsbc bank%'

// COMMAND ----------

// DBTITLE 1,Create an ESG score based on financial news sentiments
// MAGIC %sql
// MAGIC 
// MAGIC -- we stored the sum of tone and count of articles to enable AVG operations on different slices of data
// MAGIC -- create view at an organisation level
// MAGIC CREATE OR REPLACE TEMPORARY VIEW organisation_day AS (
// MAGIC   SELECT organisation, theme, date, SUM(tone) / SUM(total) AS tone, SUM(total) AS total FROM esg_db.gdelt_gold
// MAGIC   GROUP BY organisation, theme, date
// MAGIC );
// MAGIC 
// MAGIC -- we stored the sum of tone and count of articles to enable AVG operations on different slices of data
// MAGIC -- create a view across all organisations
// MAGIC CREATE OR REPLACE TEMPORARY VIEW industry_day AS (
// MAGIC   SELECT date, theme, SUM(tone) / SUM(total) AS tone, SUM(total) AS total FROM esg_db.gdelt_gold
// MAGIC   GROUP BY date, theme
// MAGIC );
// MAGIC 
// MAGIC -- our crude ESG score is the average difference between organisation sentiment vs. industries
// MAGIC -- we apply heuristic filters to remove noise from GDELT, only looking at clear connections
// MAGIC CREATE TABLE esg_db.scores USING delta AS
// MAGIC SELECT
// MAGIC   t.organisation,
// MAGIC   t.theme,
// MAGIC   SUM(t.total) AS total,
// MAGIC   COUNT(*) AS days,
// MAGIC   AVG(t.diff) AS esg
// MAGIC FROM (
// MAGIC   SELECT 
// MAGIC     o.date, 
// MAGIC     o.organisation, 
// MAGIC     o.tone - i.tone AS diff, 
// MAGIC     o.total,
// MAGIC     o.theme
// MAGIC   FROM organisation_day o
// MAGIC   JOIN industry_day i
// MAGIC   ON o.date = i.date AND o.theme = i.theme
// MAGIC ) t
// MAGIC GROUP BY t.organisation, t.theme
// MAGIC HAVING days > 300 AND total > 1000; 
// MAGIC 
// MAGIC SELECT organisation, theme, esg FROM esg_db.scores 
// MAGIC ORDER BY esg 
// MAGIC DESC;

// COMMAND ----------

// MAGIC %sql
// MAGIC 
// MAGIC 
// MAGIC CREATE OR REPLACE TEMPORARY VIEW organisation_day AS (
// MAGIC   SELECT organisation, theme, date, SUM(tone) / SUM(total) AS tone, SUM(total) AS total FROM esg_db.gdelt_gold
// MAGIC   GROUP BY organisation, theme, date
// MAGIC );
// MAGIC 
// MAGIC CREATE OR REPLACE TEMPORARY VIEW industry_day AS (
// MAGIC   SELECT date, theme, SUM(tone) / SUM(total) AS tone, SUM(total) AS total FROM esg_db.gdelt_gold
// MAGIC   GROUP BY date, theme
// MAGIC );
// MAGIC 
// MAGIC 
// MAGIC SELECT
// MAGIC   t.organisation,
// MAGIC   t.theme,
// MAGIC   SUM(t.total) AS total,
// MAGIC   COUNT(*) AS days,
// MAGIC   AVG(t.diff) AS esg
// MAGIC FROM (
// MAGIC   SELECT 
// MAGIC     o.date, 
// MAGIC     o.organisation, 
// MAGIC     o.tone - i.tone AS diff, 
// MAGIC     o.total,
// MAGIC     o.theme
// MAGIC   FROM organisation_day o
// MAGIC   JOIN industry_day i
// MAGIC   ON o.date = i.date AND o.theme = i.theme
// MAGIC ) t
// MAGIC GROUP BY t.organisation, t.theme
// MAGIC HAVING days > 300 AND total > 1000; 

// COMMAND ----------

// MAGIC %sql 
// MAGIC SELECT distinct organisation FROM esg_db.scores

// COMMAND ----------

// DBTITLE 1,Migrating ESG Scores Raw Data to Synapse
// MAGIC %sql
// MAGIC CREATE TABLE esg_db.srcESGScores  USING delta AS
// MAGIC SELECT * 
// MAGIC FROM esg_db.scores

// COMMAND ----------

// DBTITLE 1,Intermediary Transfer
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

//read data from source table
//create a streaming dataframe to store data in an intermediate table
val streamDf = spark 
  .readStream                                                  // Reading as a stream, processing record since last check point
  .format("delta")                                              // Reading from a delta table
  .table("esg_db.srcESGScores")  //Main source table
  .withColumn("IsMigrated", lit(0)) 

//Create a chekpoint of last insertion
//checkpoint makes sure that the only the changes in the source data, if any, will be stored in intermediate data
streamDf
  .writeStream                                                                  // Writing data as a stream
  .trigger(Trigger.Once)                                                       // Create a streaming job triggered only once...
  .option("checkpointLocation", "/esg_checkpoint/dbrESGScores_3") //Don't change checkpoint location (processes data since last checkpoint)
  .format("delta")                                                              // write to delta table
  .table("esg_db.dbrESGScores")   //Save to intermediary Databricks table

// COMMAND ----------

// DBTITLE 1,To Synapse
// //Configuration settings to connect to blob storage
//spark.conf.set("fs.azure.account.key.#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net","#STORAGE_ACCOUNT_KEY#"))

//val sqluser =  dbutils.secrets.get(scope="esgmigratecreds", key="sqluser")
//val sqlpassword = dbutils.secrets.get(scope="esgmigratecreds", key="sqlpassword")
//val dbtable = "ADB_ESGScores"  //Synapse Table Name Set here
//val url = s"jdbc:sqlserver://#WORKSPACE_NAME#.sql.azuresynapse.net:1433;database=#DATABASE_NAME#;user=#SQL_USERNAME#;password=#SQL_PASSWORD#;encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.sql.azuresynapse.net;loginTimeout=30;authentication=ActiveDirectoryPassword"

// //Read only newer records from our intermediary table in Databricks
// var migrate_df = spark.sql("SELECT Organisation, Theme, Total, Days, ESG, current_timestamp() as ReportedOn FROM esg_db.dbrESGScores WHERE IsMigrated = 0")
 
// print(s"Total Records", migrate_df.count())
// print("\n")

// //Send new records to synapse for further processing
// migrate_df.write.format("com.databricks.spark.sqldw").option("forwardSparkAzureStorageCredentials", "true").mode("append").option("url", url).option("dbtable", dbtable).option("tempDir", "abfss://esg-migrate@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/tempDirs").save()

// //Mark records as migrated after successfully saved to synapase
// spark.sql("UPDATE esg_db.dbrESGScores SET IsMigrated = 1 WHERE IsMigrated = 0")


// COMMAND ----------

// MAGIC %md
// MAGIC ## `STEP5`: Create a network based ESG score
// MAGIC 
// MAGIC As mentioned in the introduction, we want to bring more context to companies ESG beyond news coverage. We want a company's important connections (mentioned in news articles altogether) to also contribute to a company's ESG - positively or negatively - proportional to their importance, hence a network approach. Using [Graphframes](https://graphframes.github.io/graphframes/docs/_site/index.html), we can easily create a network of companies sharing financial news articles. The more companies are mentioned altogether, the stronger their link will be (edge weight). This graph will allow us to find companies importance relative to our core FSIs we would like to assess.

// COMMAND ----------

// DBTITLE 1,Create our nodes dataframe
import org.apache.spark.sql.functions._

// Companies will be considered as vertex in our network, edge will contain the number of shared news articles
val nodes = spark
  .read
  .table("esg_db.scores")
  .select(col("organisation").as("id"))
  .distinct()

// COMMAND ----------

// MAGIC %sql
// MAGIC Select COUNT(*) from esg_db.scores

// COMMAND ----------

// DBTITLE 1,Create our edges dataframe
import org.apache.spark.sql.functions._

// GDELT has nasty habit to categorize united states or european as organisations
// We can also remove nodes we know are common, such as reuters
// This list is obviously not exhaustive and may be tweaked depending on your strategy
val blacklist = spark.sparkContext.broadcast(Set("united states", "european union", "reuters"))

// Given mentions of multiple organisations within a given URL, build all combinations as tuples
// Graph will be undirected so we register both directions - doubling our graph size!
val buildTuples = udf((xs: Seq[String]) => {
  val organisations = xs.filter(x => !blacklist.value.contains(x))
  organisations.flatMap(x1 => {
    organisations.map(x2 => {
      (x1, x2)
    })
  }).toSeq.filter({ case (x1, x2) =>
    x1 != x2 // remove self edges
  })
})

// build organisations tuples
// Our graph follows a power of law distributions in term of edge weights
// more than 90% of the connections have no more than 100 articles in common
// Reducing the number of edges in our graph from 51,679,930 down to 61,143 using 200 filter
val edges = spark.read.table("esg_db.gdelt_silver")
  .groupBy("url")
  .agg(collect_list(col("organisation")).as("organisations"))
  .withColumn("tuples", buildTuples(col("organisations")))
  .withColumn("tuple", explode(col("tuples")))
  .withColumn("src", col("tuple._1"))
  .withColumn("dst", col("tuple._2"))
  .groupBy("src", "dst")
  .agg(sum(lit(1)).as("relationship"))
  .filter(col("relationship") > 200)

display(edges)

// COMMAND ----------

// DBTITLE 1,Create our Graph object
import org.graphframes.GraphFrame
val esgGraph = GraphFrame(nodes, edges).cache()
println("Number of nodes : " + esgGraph.vertices.count()) //2,611
println("Number of edges : " + esgGraph.edges.count()) //107,894

// COMMAND ----------

// DBTITLE 1,Consider our FSIs as Landmarks
// Whether we run a personalised page rank or shortest path, we do so relative to our core FSI we would like to score
// These nodes will be considered as landmarks for the following graph analytics
// Let's make sure any of our FSIs are included in our graph
val landmarks = esgGraph
  .vertices
  .select("id")
  //`isin` takes a vararg, not a list, so expand our list to args
  .filter(col("id").isin(organisationAltNames.keys.toArray:_*))
  .rdd
  .map(_.getAs[String]("id"))
  .collect

// COMMAND ----------

// MAGIC %md
// MAGIC The [depth](https://www.sciencedirect.com/science/article/pii/S0022000077800329) of a graph is the maximum of all its shortest paths. To put it another way, it as how many hops at most do you need to reach two seperate companies of our network. In our case, we want to limit our network to at most 4 connections to our FSI nodes. To do so, we run a [shortestpath](https://en.wikipedia.org/wiki/Shortest_path_problem) algorithm first using our FSIs as 'landmarks'. This returns a dataframe of vertices (companies) with their associated distances to each of our landmark (that we can filter for distance < 5)

// COMMAND ----------

// DBTITLE 1,Limit our graph depth to max 4
// As our network can be fairly big, we want to first filter nodes we know would not contribute much to ESG score
// Either because they are too "far away" (using shortest path)
// Or not reachable from our ESG nodes (connected component)
val shortestPaths = esgGraph
  .shortestPaths
  .landmarks(landmarks)
  .run()

// Either way, we run a shortest path algorithm and filter for maximum 5 hops from our core FSIs 
// Note that we chose 5 as a starting point, can be confirmed by looking at distribution of distances
val filterDepth = udf((distances: Map[String, Int]) => {
  distances.values.exists(distance => distance < 5)
})

// By applying this filter upfront, we reduced number of edges by 2
// Filtering upfront will allow us to use personalised page rank with more iterations and faster 
val esgDenseGraph = GraphFrame(shortestPaths, edges).filterVertices(filterDepth(col("distances"))).cache()
println("Number of nodes : " + esgDenseGraph.vertices.count()) //2,308
println("Number of edges : " + esgDenseGraph.edges.count()) //54,150

// COMMAND ----------

// MAGIC %md
// MAGIC With our graph filtered to maximum 4 hops, we can afford to be more greedy with page rank algorithm by increasing the number of iterations required to better estimate company's connections relative importances. We will use a personalized page rank algorithm, support by graphframe (and underlying GraphX) natively.

// COMMAND ----------

// DBTITLE 1,Run a personalised page rank to find relation importance
val prNodes = esgDenseGraph
  .parallelPersonalizedPageRank
  .resetProbability(0.15)
  // with our graph reduced to max 4 hops, we run 100 iterations to better estimate importance
  .maxIter(100)
  // interestingly, Graphframes complains if not type of `Array[Any]`
  .sourceIds(landmarks.asInstanceOf[Array[Any]])
  .run()

// COMMAND ----------

// DBTITLE 1,Get connections importance
import org.apache.spark.ml.linalg.Vector

// Page rank returns output as a vector containing personalised page rank score for each landmark
// We extract the relevant organisation and score from the returned vector
val landmarksB = spark.sparkContext.broadcast(landmarks)
val importances = udf((pr: Vector) => {
  pr.toArray.zipWithIndex.map({ case (importance, id) =>
    (landmarksB.value(id), importance)
  })
})

// We explode our page rank importances into tuple of [organisation <importance> connection]
val connections = prNodes
  .vertices
  .withColumn("importances", importances(col("pageranks")))
  .withColumn("importance", explode(col("importances")))
  .select(
    col("importance._1").as("organisation"),
    col("id").as("connection"),
    col("importance._2").as("importance")
  )

// COMMAND ----------

// DBTITLE 1,Get a weighted ESG contribution based on connection importance
// We join the page rank score (importance) with ESG internal score for each connection
val connectionsContributions = spark
  .read
  .table("esg_db.scores")
  .withColumnRenamed("organisation", "connection")
  .join(connections, List("connection"))
  .select("organisation", "connection", "theme", "esg", "importance")

// Save our results back to delta
connectionsContributions
  .write
  .mode("overwrite")
  .format("delta")
  .saveAsTable("esg_db.connections")

// COMMAND ----------

// MAGIC %md
// MAGIC We can directly visualize the top 100 influential nodes to a specific business (in this case Barclays PLC) as per below graph. Without any surprise, Barclays is well connected with most of our core FSIs (such as JP Morgan Chase, Goldman Sachs or Credit Suisse), but also to the Security Exchange Commission, Federal Reserve and International Monetary Fund. Further down this distribution, we find public and private companies such as Huawei, Chevron, Starbucks or Johnson and Johnson. Strongly or loosely related, directly or indirectly connected, all these businesses (or entities from an NLP standpoint) could theoretically affect Barclays ESG performance, either positively or negatively, and as such impact Barclays reputation.

// COMMAND ----------

// MAGIC %sql
// MAGIC SELECT * FROM esg_db.connections  where importance > 0

// COMMAND ----------

// DBTITLE 1,Show Woodgrove important connections
// MAGIC %sql
// MAGIC SELECT connection, importance FROM esg_db.connections
// MAGIC WHERE organisation = 'Woodgrove'
// MAGIC AND connection != 'Woodgrove'
// MAGIC ORDER BY importance DESC
// MAGIC LIMIT 200

// COMMAND ----------

// DBTITLE 1,Migrating Organization Connections Raw Data to Synapse
// MAGIC %sql
// MAGIC CREATE TABLE esg_db.srcESGOrgConnections  USING delta AS
// MAGIC SELECT * 
// MAGIC FROM esg_db.connections WHERE organisation = 'barclays' AND connection != 'barclays' --Organisation Name to be added

// COMMAND ----------

// DBTITLE 1,Intermediary Transfer
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

//read data from source table
val streamDf = spark 
  .readStream                                                    // Reading as a stream, processing record since last check point
  .format("delta")                                              // Reading from a delta table
  .table("esg_db.srcESGOrgConnections")                        //Main source table
  .withColumn("IsMigrated", lit(0))                           //IsMigrated helps us keep a check on the data that we have already migrated, therefore minimizing redundant pulling of data

//Create a chekpoint of last insertion
//checkpoint makes sure that the only the changes in the source data, if any, will be stored in intermediate data
streamDf
  .writeStream                                                                        // Writing data as a stream
  .trigger(Trigger.Once)                                                             // Create a streaming job triggered only once...
  .option("checkpointLocation", "/esg_checkpoint/dbrESGOrgConnections_3")           //Don't change checkpoint location (processes data since last checkpoint)
  .format("delta")                                                                 // write to delta table
  .table("esg_db.dbrESGOrgConnections")                                           //Save to intermediary Databricks table

// COMMAND ----------

// DBTITLE 1,To Synapse
// //Configuration settings to connect to blob storage
// spark.conf.set("fs.azure.account.key.#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net","#STORAGE_ACCOUNT_KEY#"))

// val sqluser =  dbutils.secrets.get(scope="esgmigratecreds", key="sqluser")
// val sqlpassword = dbutils.secrets.get(scope="esgmigratecreds", key="sqlpassword")
// val dbtable = "ADB_ESGOrgConnections" //Synapse Table Name Set here
// val url = s"jdbc:sqlserver://#WORKSPACE_NAME#.sql.azuresynapse.net:1433;database=#DATABASE_NAME#;user=#SQL_USERNAME#;password=#SQL_PASSWORD#;encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.sql.azuresynapse.net;loginTimeout=30;authentication=ActiveDirectoryPassword"

// //Read only newer records from our intermediary table in Databricks
// var migrate_df = spark.sql("SELECT Organisation, Connection, Importance, current_timestamp() as ReportedOn FROM esg_db.dbrESGOrgConnections WHERE IsMigrated = 0")
 
// print(s"Total Records", migrate_df.count())
// print("\n")

// //Send new records to synapse for further processing
// migrate_df.write.format("com.databricks.spark.sqldw").option("forwardSparkAzureStorageCredentials", "true").mode("append").option("url", url).option("dbtable", dbtable).option("tempDir", "abfss://esg-migrate@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/tempDirs").save()

// //Mark records as migrated after successfully saved to synapase
// spark.sql("UPDATE esg_db.dbrESGOrgConnections SET IsMigrated = 1 WHERE IsMigrated = 0")


// COMMAND ----------

// DBTITLE 1,Compute weighted ESG score
// weighted ESG as SUM[organisation_esg x organisation_importance] / SUM[organisation_importance]
val scores_norm = connectionsContributions
  .withColumn("weightedEsg", col("esg") * col("importance"))
  .groupBy("organisation", "theme")
  .agg(
    sum("weightedEsg").as("totalWeightedEsg"),
    sum("importance").as("totalImportance")
  )
  .withColumn("weightedEsg", col("totalWeightedEsg") / col("totalImportance"))
  .select(col("organisation"), col("theme"), col("weightedEsg").as("esg"))

// Display weighted scores
 display(scores_norm)

// COMMAND ----------

// DBTITLE 1,Migrating Weighted ESG Score Raw Data to Synapse
Saving required dataframe data to intermediary source table
scores_norm
  .write
  .mode("append")
  .format("delta")
  .saveAsTable("esg_db.srcESGWeightedScore")

// COMMAND ----------

// DBTITLE 1,Intermediary Transfer
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

//read data from source table
val streamDf = spark 
  .readStream                                                    // Reading as a stream, processing record since last check point
  .format("delta")                                              // Reading from a delta table
  .table("esg_db.srcESGWeightedScore")                         //Main source table
  .withColumn("IsMigrated", lit(0)) 

//Create a chekpoint of last insertion
streamDf
  .writeStream                                                                              // Writing data as a stream
  .trigger(Trigger.Once)                                                                   // Create a streaming job triggered only once...
  .option("checkpointLocation", "/esg_checkpoint/dbrESGWeightedScore_3")                  //Don't change checkpoint location (processes data since last checkpoint)
  .format("delta")                                                                       // write to delta table
  .table("esg_db.dbrESGWeightedScore")                                                  //Save to intermediary Databricks table

// COMMAND ----------

// DBTITLE 1,To Synapse
// //Configuration settings to connect to blob storage
//spark.conf.set( "fs.azure.account.key.#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net","#STORAGE_ACCOUNT_KEY#"))

// val sqluser =  dbutils.secrets.get(scope="esgmigratecreds", key="sqluser")
//val sqlpassword = dbutils.secrets.get(scope="esgmigratecreds", key="sqlpassword")
//val dbtable = "ADB_ESGWeightedScore" //Synapse Table Name Set here
//val url = s"jdbc:sqlserver://#WORKSPACE_NAME#.sql.azuresynapse.net:1433;database=#DATABASE_NAME#;user=#SQL_USERNAME#;password=#SQL_PASSWORD#;encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.sql.azuresynapse.net;loginTimeout=30;authentication=ActiveDirectoryPassword"

// //Read only newer records from our intermediary table in Databricks
// var migrate_df = spark.sql("SELECT Organisation, Theme, ESG, current_timestamp() as ReportedOn FROM esg_db.dbrESGWeightedScore WHERE IsMigrated = 0")
 
// print(s"Total Records", migrate_df.count())
// print("\n")

// //Send new records to synapse for further processing
// migrate_df.write.format("com.databricks.spark.sqldw").option("forwardSparkAzureStorageCredentials", "true").mode("append").option("url", url).option("dbtable", dbtable).option("tempDir", "abfss://esg-migrate@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/tempDirs").save()

// //Mark records as migrated after successfully saved to synapase
// spark.sql("UPDATE esg_db.dbrESGWeightedScore SET IsMigrated = 1 WHERE IsMigrated = 0")

// COMMAND ----------

// MAGIC %md
// MAGIC By combining our ESG score captured earlier with the importance of each of these entities, it becomes easy to apply a weighted average on the “Barclays network” where each business contributes to Barclays ESG score proportionally to its relative importance. We call this approach a **propagated weighted ESG score**. We observe the negative or positive influence of any company’s network using a word cloud visualization. In the picture below, we show the negative influence (entities contributing negatively to ESG relative to) for Morgan Stanley. 

// COMMAND ----------

// MAGIC %python
// MAGIC dbutils.library.installPyPI('wordcloud')

// COMMAND ----------

// DBTITLE 1,The "Woodgrove" detractors network
// MAGIC %python
// MAGIC 
// MAGIC from pyspark.sql import functions as F
// MAGIC import matplotlib.pyplot as plt
// MAGIC from wordcloud import WordCloud
// MAGIC import numpy as np
// MAGIC import random
// MAGIC 
// MAGIC organisation = 'Woodgrove'
// MAGIC 
// MAGIC # retrieve all connections for a given organisation
// MAGIC connections = spark.read.table("esg_db.connections") \
// MAGIC     .filter(F.col("theme") == 'E').filter(F.col("organisation") == organisation) \
// MAGIC     .toPandas().set_index('connection')[['importance', 'esg']]
// MAGIC 
// MAGIC # retrieve organisation ESG score
// MAGIC esg = connections.loc[organisation].esg
// MAGIC 
// MAGIC # get all companies contributing negatively
// MAGIC detractors = connections[connections['esg'] < esg]
// MAGIC 
// MAGIC # create a dictionary for each detractor with esg influence
// MAGIC detractors_importance = dict(zip(detractors.index, detractors.importance))
// MAGIC 
// MAGIC # build a wordcloud object
// MAGIC detractors_wc = WordCloud(
// MAGIC       background_color="white",
// MAGIC       max_words=5000, 
// MAGIC       width=600, 
// MAGIC       height=400, 
// MAGIC       contour_width=3, 
// MAGIC       contour_color='steelblue'
// MAGIC   ).generate_from_frequencies(detractors_importance)
// MAGIC 
// MAGIC # plot wordcloud
// MAGIC figure = plt.figure(figsize=(10, 10))
// MAGIC plt.imshow(detractors_wc)
// MAGIC plt.axis('off')
// MAGIC display(figure)

// COMMAND ----------

// DBTITLE 1,Migrating Organization Detractors Network Word Cloud Raw Data to Synapse
// MAGIC %python
// MAGIC #Saving required dataframe data to intermediary source table
// MAGIC from pyspark.sql.functions import *
// MAGIC detractor_dict_list = list(map(list, detractors_importance.items()))
// MAGIC detractor_df = spark.createDataFrame(detractor_dict_list, ["company", "importance"])
// MAGIC detractor_df = detractor_df.withColumn('organisation', lit(organisation))
// MAGIC 
// MAGIC detractor_df \
// MAGIC .write \
// MAGIC .mode("append") \
// MAGIC .format("delta") \
// MAGIC .saveAsTable("esg_db.srcEsgOrgDetractors")

// COMMAND ----------

// DBTITLE 1,Intermediary Transfer
import org.apache.spark.sql.functions._
import org.apache.spark.sql.streaming.Trigger

//read data from source table
val streamDf = spark 
  .readStream                                                    // Reading as a stream, processing record since last check point
  .format("delta")                                              // Reading from a delta table
  .table("esg_db.srcEsgOrgDetractors")                         //Main source table
  .withColumn("IsMigrated", lit(0))                           //IsMigrated helps us keep a check on the data that we have already migrated, therefore minimizing redundant pulling of data

//Create a chekpoint of last insertion
streamDf
  .writeStream                                                                           // Writing data as a stream
  .trigger(Trigger.Once)                                                                // Create a streaming job triggered only once...
  .option("checkpointLocation", "/esg_checkpoint/dbrEsgOrgDetractors_4")               //Don't change checkpoint location (processes data since last checkpoint)
  .format("delta")                                                                    // write to delta table
  .table("esg_db.dbrEsgOrgDetractors")                                               //Save to intermediary Databricks table

// COMMAND ----------

// DBTITLE 1,To Synapse
// //Configuration settings to connect to blob storage
// spark.conf.set("fs.azure.account.key.#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net","#STORAGE_ACCOUNT_KEY#"))


// declaring the sql pool credentials
// val sqluser =  dbutils.secrets.get(scope="esgmigratecreds", key="sqluser")
// val sqlpassword = dbutils.secrets.get(scope="esgmigratecreds", key="sqlpassword")
// val dbtable = "ADB_EsgOrgDetractors" //Synapse Table Name Set here
// val url = s"jdbc:sqlserver://#WORKSPACE_NAME#.sql.azuresynapse.net:1433;database=#DATABASE_NAME#;user=#SQL_USERNAME#;password=#SQL_PASSWORD#;encrypt=true;trustServerCertificate=true;hostNameInCertificate=*.sql.azuresynapse.net;loginTimeout=30;authentication=ActiveDirectoryPassword"

// //Read only newer records from our intermediary table in Databricks
// var migrate_df = spark.sql("SELECT Organisation, Company, Importance, current_timestamp() as ReportedOn FROM esg_db.dbrEsgOrgDetractors WHERE IsMigrated = 0")
 
// print(s"Total Records", migrate_df.count())
// print("\n")

// //Send new records to synapse for further processing
// migrate_df.write.format("com.databricks.spark.sqldw").option("forwardSparkAzureStorageCredentials", "true").mode("append").option("url", url).option("dbtable", dbtable).option("tempDir", "abfss://esg-migrate@#STORAGE_ACCOUNT_NAME#.dfs.core.windows.net/tempDirs").save()

// //Mark records as migrated after successfully saved to synapase
// spark.sql("UPDATE esg_db.dbrEsgOrgDetractors SET IsMigrated = 1 WHERE IsMigrated = 0")

// COMMAND ----------

// MAGIC %md
// MAGIC Using news analytics, we demonstrated how to compare sentiment across multiple themes and accross industries in order to derive an internal ESG score. And although this score could be a crude approach to ESG, the key message was to show how to leverage graph analytics to understand the connection importance and their negative or positive contribution. In real life, one would need to augment this framework with the internal data they have about their different investments in order to build stronger connections and extract similar patterns before a news has been made public, hence mitigating serious reputation risks upfront.
