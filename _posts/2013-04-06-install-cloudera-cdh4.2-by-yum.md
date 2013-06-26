---
layout: post
title:  从yum安装Cloudera CDH4.2
date:  2013-04-06 17:00
category: hadoop
tags: [hadoop, impala, cloudera]
keywords: yum, cdh, hadoop, hbase, hive, zookeeper, cloudera
description: 从yum安装Cloudera CDH4.2
---

记录使用yum通过rpm方式安装Cloudera CDH4.2中的hadoop、yarn、HBase，需要注意初始化namenode之前需要手动创建一些目录并设置权限。

## 目录
1. 安装jdk
2. 设置yum源
3. 安装HDFS
4. 配置hadoop
5. 安装YARN
6. 安装zookeeper
7. 安装HBase
8. 安装Hive
9. 参考文章

## 1. 安装jdk
安装jdk并设置环境变量

	export JAVA_HOME=< jdk-install-dir>
	export PATH=$JAVA_HOME/bin:$PATH

检查环境变量中是否有设置JAVA_HOME

	sudo env | grep JAVA_HOME

如果env中没有JAVA_HOME变量，则修改/etc/sudoers文件
	
	vi /etc/sudoers
	Defaults env_keep+=JAVA_HOME

## 2. 设置yum源
从http://archive.cloudera.com/cdh4/repo-as-tarball/4.2.0/cdh4.2.0-centos6.tar.gz 下载压缩包解压并设置本地或ftp yum源，可以参考[Creating a Local Yum Repository](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_30.html)

## 3. 安装HDFS
### 在NameNode节点yum安装

	yum list hadoop
	yum install hadoop-hdfs-namenode
	yum install hadoop-hdfs-secondarynamenode
	yum install hadoop-yarn-resourcemanager
	yum install hadoop-mapreduce-historyserver

### 在DataNode节点yum安装 

	yum list hadoop
	yum install hadoop-hdfs-datanode
	yum install hadoop-yarn-nodemanager
	yum install hadoop-mapreduce
	yum install zookeeper-server
	yum install hadoop-httpfs
	yum install hadoop-debuginfo


## 4. 配置hadoop
### 修改配置文件
hadoop的默认配置文件在/etc/hadoop/conf

1. core-site.xml:


	<property>
	    <name>fs.defaultFS</name>
	    <value>hdfs://node1</value>
	</property>
	
	<property>
		<name>fs.trash.interval</name>
		<value>10080</value>
	</property>
	
	<property>
		<name>fs.trash.checkpoint.interval</name>
		<value>10080</value>
	</property>
	
	<property>
	  <name>io.bytes.per.checksum</name>
	  <value>4096</value>
	</property>


2. hdfs-site.xml:


	<property>
	  <name>dfs.replication</name>
	  <value>3</value>
	</property>
	
	<property>
	  <name>hadoop.tmp.dir</name>
	  <value>/opt/data/hadoop</value>
	</property>
	
	<property>
	    <name>dfs.block.size</name>
	    <value>268435456</value>
	</property>
	
	<property>
	  <name>dfs.permissions.superusergroup</name>
	  <value>hadoop</value>
	</property>
	
	<property>
	  <name>dfs.namenode.handler.count</name>
	  <value>100</value>
	</property>
	<property>
	  <name>dfs.datanode.handler.count</name>
	  <value>100</value>
	</property>
	<property>
	  <name>dfs.datanode.balance.bandwidthPerSec</name>
	  <value>1048576</value>
	  <description>
		Specifies the maximum amount of bandwidth that each datanode
		can utilize for the balancing purpose in term of
		the number of bytes per second.
	  </description>
	</property>
	<property>
		<name>dfs.namenode.http-address</name>
		<value>node1:50070</value>
	</property>
	<property>
		<name>dfs.namenode.secondary.http-address</name>
		<value>node1:50090</value>
	</property>
	<property>
		<name>dfs.webhdfs.enabled</name>
		<value>true</value>
	</property>


3. 修改master和slaves文件

### NameNode HA
https://ccp.cloudera.com/display/CDH4DOC/Introduction+to+HDFS+High+Availability

### Secondary NameNode Parameters
在hdfs-site.xml中可以配置以下参数：

	dfs.namenode.checkpoint.check.period
	dfs.namenode.checkpoint.txns
	dfs.namenode.checkpoint.dir
	dfs.namenode.checkpoint.edits.dir
	dfs.namenode.num.checkpoints.retained

#### multi-host-secondarynamenode-configuration
http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/.

### Config list

	Directory						Owner		Permissions	Default Path
	hadoop.tmp.dir					hdfs:hdfs	drwx------	/var/hadoop
	dfs.namenode.name.dir				hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/name
	dfs.datanode.data.dir				hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/data
	dfs.namenode.checkpoint.dir			hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/namesecondary
	yarn.nodemanager.local-dirs			yarn:yarn	drwxr-xr-x	${hadoop.tmp.dir}/nm-local-dir
	yarn.nodemanager.log-dirs			yarn:yarn	drwxr-xr-x	${yarn.log.dir}/userlogs
	yarn.nodemanager.remote-app-log-dir						/tmp/logs

my set:

	hadoop.tmp.dir					/opt/data/hadoop
	dfs.namenode.name.dir				${hadoop.tmp.dir}/dfs/name
	dfs.datanode.data.dir				${hadoop.tmp.dir}/dfs/data
	dfs.namenode.checkpoint.dir			${hadoop.tmp.dir}/dfs/namesecondary
	yarn.nodemanager.local-dirs			/opt/data/yarn/local
	yarn.nodemanager.log-dirs			/var/log/hadoop-yarn/logs
	yarn.nodemanager.remote-app-log-dir 		/var/log/hadoop-yarn/app


### Create the data Directory in the Cluster
在namenode节点创建name目录

	mkdir -p /opt/data/hadoop/dfs/name
	chown -R hdfs:hdfs /opt/data/hadoop/dfs/name
	chmod 700 /opt/data/hadoop/dfs/name

在所有datanode节点创建data目录

	mkdir -p /opt/data/hadoop/dfs/data
	chown -R hdfs:hdfs /opt/data/hadoop/dfs/data
	chmod 700 /opt/data/hadoop/dfs/data

在secondarynode节点创建namesecondary目录

	mkdir -p /opt/data/hadoop/dfs/namesecondary
	chown -R hdfs:hdfs /opt/data/hadoop/dfs/namesecondary
	chmod 700 /opt/data/hadoop/dfs/namesecondary

在所有datanode节点创建yarn的local目录

	mkdir -p /opt/data/hadoop/yarn/local
	chown -R yarn:yarn /opt/data/hadoop/yarn/local
	chmod 700 /opt/data/hadoop/yarn/local

### 同步配置文件到整个集群

	sudo scp -r /etc/hadoop/conf root@nodeX:/etc/hadoop/conf

### 格式化NameNode

	sudo -u hdfs hdfs namenode -format

### 在每个节点启动hdfs

	for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x restart ; done


## 5. 安装YARN
先在一台机器上配置好，然后在做同步。

1. mapred-site.xml:


	<property>
	    <name>mapreduce.framework.name</name>
	    <value>yarn</value>
	</property>
	
	<property>
	 	<name>mapreduce.jobhistory.address</name>
	 	<value>node1:10020</value>
	</property>
	
	<property>
	 	<name>mapreduce.jobhistory.webapp.address</name>
	 	<value>node1:19888</value>
	</property>
	
	<property>
	  <name>mapreduce.task.io.sort.factor</name>
	  <value>100</value>
	  <description>The number of streams to merge at once while sorting
	  files.  This determines the number of open file handles.</description>
	</property>
	<property>
	  <name>mapreduce.task.io.sort.mb</name>
	  <value>200</value>
	  <description>The total amount of buffer memory to use while sorting 
	  files, in megabytes.  By default, gives each merge stream 1MB, which
	  should minimize seeks.</description>
	</property>
	<property>
	  <name>mapreduce.reduce.shuffle.parallelcopies</name>
	  <value>16</value>
	   <!-- 一般介于节点数开方和节点数一半之间，小于20节点，则为节点数-->
	  <description>The default number of parallel transfers run by reduce
	  during the copy(shuffle) phase.
	  </description>
	</property>
	<property>
	  <name>mapreduce.task.timeout</name>
	  <value>1800000</value>
	</property>
	<property>
	  <name>mapreduce.tasktracker.map.tasks.maximum</name>
	  <value>4</value>
	</property>
	<property>
	  <name>mapreduce.tasktracker.reduce.tasks.maximum</name>
	  <value>2</value>
	</property>


2. yarn-site.xml:


	<property>
	    <name>yarn.resourcemanager.resource-tracker.address</name>
	    <value>node1:8031</value>
	</property>
	<property>
	    <name>yarn.resourcemanager.address</name>
	    <value>node1:8032</value>
	</property>
	<property>
	    <name>yarn.resourcemanager.scheduler.address</name>
	    <value>node1:8030</value>
	</property>
	<property>
	    <name>yarn.resourcemanager.admin.address</name>
	    <value>node1:8033</value>
	</property>
	<property>
	    <name>yarn.resourcemanager.webapp.address</name>
	    <value>node1:8088</value>
	</property>
	<property>
	    <name>yarn.nodemanager.aux-services</name>
	    <value>mapreduce.shuffle</value>
	</property>
	<property>
	    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
	    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
	</property>
	<property>
	    <name>yarn.log-aggregation-enable</name>
	    <value>true</value>
	</property>
	<property>
	    <description>Classpath for typical applications.</description>
	    <name>yarn.application.classpath</name>
	    <value>
		$HADOOP_CONF_DIR,
		$HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
		$HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
		$HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
		$YARN_HOME/*,$YARN_HOME/lib/*
	    </value>
	</property>
	<property>
	    <name>yarn.nodemanager.local-dirs</name>
	    <value>/opt/hadoop/yarn/local</value>
	</property>
	<property>
	    <name>yarn.nodemanager.log-dirs</name>
	    <value>/var/log/hadoop-yarn/logs</value>
	</property>
	<property>
	    <name>yarn.nodemanager.remote-app-log-dir</name>
	    <value>/var/log/hadoop-yarn/apps</value>
	</property>
	<property>
	    <name>yarn.app.mapreduce.am.staging-dir</name>
	    <value>/user</value>
	</property>


### HDFS创建临时目录

	sudo -u hdfs hadoop fs -mkdir /tmp
	sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

### 创建日志目录

	sudo -u hdfs hadoop fs -mkdir /user/history
	sudo -u hdfs hadoop fs -chmod -R 1777 /user/history
	sudo -u hdfs hadoop fs -chown yarn /user/history
	sudo -u hdfs hadoop fs -mkdir /var/log/hadoop-yarn
	sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn

### 验证hdfs结构是否正确

	[root@node1 data]# sudo -u hdfs hadoop fs -ls -R /
	drwxrwxrwt   - hdfs supergroup          0 2012-04-19 14:31 /tmp
	drwxr-xr-x   - hdfs supergroup          0 2012-05-31 10:26 /user
	drwxrwxrwt   - yarn supergroup          0 2012-04-19 14:31 /user/history
	drwxr-xr-x   - hdfs   supergroup        0 2012-05-31 15:31 /var
	drwxr-xr-x   - hdfs   supergroup        0 2012-05-31 15:31 /var/log
	drwxr-xr-x   - yarn   mapred        	0 2012-05-31 15:31 /var/log/hadoop-yarn


### 启动mapred-historyserver 

	/etc/init.d/hadoop-mapreduce-historyserver start

### 在每个节点启动YARN

	for x in `cd /etc/init.d ; ls hadoop-yarn-*` ; do sudo service $x start ; done

### 为每个MapReduce用户创建主目录

	sudo -u hdfs hadoop fs -mkdir /user/$USER
	sudo -u hdfs hadoop fs -chown $USER /user/$USER

### Set HADOOP_MAPRED_HOME

	export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce

### Configure the Hadoop Daemons to Start at Boot Time
https://ccp.cloudera.com/display/CDH4DOC/Maintenance+Tasks+and+Notes#MaintenanceTasksandNotes-ConfiguringinittoStartCoreHadoopSystemServices

## 6. 安装Zookeeper
安装zookeeper

	yum install zookeeper*

设置crontab
	
	crontab -e
	15 * * * * java -cp $classpath:/usr/lib/zookeeper/lib/log4j-1.2.15.jar:\
	/usr/lib/zookeeper/lib/jline-0.9.94.jar:\	
	/usr/lib/zookeeper/zookeeper.jar:/usr/lib/zookeeper/conf\
	org.apache.zookeeper.server.PurgeTxnLog /var/zookeeper/ -n 5

在每个需要安装zookeeper的节点上创建zookeeper的目录

	mkdir -p /opt/data/zookeeper
	chown -R zookeeper:zookeeper /opt/data/zookeeper

设置zookeeper配置：/etc/zookeeper/conf/zoo.cfg，并同步到其他机器

	tickTime=2000
	initLimit=10
	syncLimit=5
	dataDir=/opt/data/zookeeper
	clientPort=2181
	server.1=node1:2888:3888
	server.2=node2:2888:3888
	server.3=node3:2888:3888

在每个节点上初始化并启动zookeeper，注意修改n值
 
	service zookeeper-server init --myid=n
	service zookeeper-server restart
 
## 7. 安装HBase

	yum install hbase*

### 在hdfs中创建/hbase

	sudo -u hdfs hadoop fs -mkdir /hbase
	sudo -u hdfs hadoop fs -chown hbase:hbase /hbase
 
### 设置crontab：

	crontab -e
	* 10 * * * cd /var/log/hbase/; rm -rf\
	`ls /var/log/hbase/|grep -P 'hbase\-hbase\-.+\.log\.[0-9]'\`>> /dev/null &


### 修改配置文件并同步到其他机器：


	<configuration>
	<property>
	    <name>hbase.distributed</name>
	    <value>true</value>
	</property>
	<property>
	    <name>hbase.rootdir</name>
	    <value>hdfs://node1:8020/hbase</value>
	</property>
	<property>
	    <name>hbase.tmp.dir</name>
	    <value>/opt/data/hbase</value>
	</property>
	<property>
	    <name>hbase.zookeeper.quorum</name>
	    <value>node1,node2,node3</value>
	</property>
	<property>
	    <name>hbase.hregion.max.filesize</name>
	    <value>536870912</value>
	    <description>
	    Maximum HStoreFile size. If any one of a column families' HStoreFiles has
	    grown to exceed this value, the hosting HRegion is split in two.
	    Default: 10G.
	    </description>
	  </property>
	  <property>
	    <name>hbase.hregion.memstore.flush.size</name>
	    <value>67108864</value>
	    <description>
	    Memstore will be flushed to disk if size of the memstore
	    exceeds this number of bytes.  Value is checked by a thread that runs
	    every hbase.server.thread.wakefrequency.
	    </description>
	  </property>
	  <property>
	    <name>hbase.regionserver.lease.period</name>
	    <value>600000</value>
	    <description>HRegion server lease period in milliseconds. Default is
	    60 seconds. Clients must report in within this period else they are
	    considered dead.</description>
	  </property>
	  <property>
	    <name>hbase.client.retries.number</name>
	    <value>3</value>
	  </property> 
	  <property>
	    <name>hbase.regionserver.handler.count</name>
	    <value>100</value>
	  </property>
	  <property>
	    <name>hbase.zookeeper.property.maxClientCnxns</name>
	    <value>2000</value>
	  </property>
	  <property>
	    <name>hfile.block.cache.size</name>
	    <value>0.1</value>
	    <description>
		Percentage of maximum heap (-Xmx setting) to allocate to block cache
		used by HFile/StoreFile. Default of 0.25 means allocate 25%.
		Set to 0 to disable but it's not recommended.
	    </description>
	  </property>
	  <property>
	    <name>hbase.regions.slop</name>
	    <value>0</value>
	    <description>Rebalance if any regionserver has average + (average * slop) regions.
	    Default is 20% slop.
	    </description>
	  </property>
	  <property>
	    <name>hbase.hstore.compactionThreshold</name>
	    <value>10</value>
	  </property>
	  <property>
	    <name>hbase.hstore.blockingStoreFiles</name>
	    <value>30</value>
	  </property>
	</configuration>


### 修改regionserver文件


### 启动HBase

	service hbase-master start
	service hbase-regionserver start

## 8. 安装hive
### 在一个节点上安装hive

	sudo yum install hive*


### 安装metastore

### 修改配置文件


	<configuration>
	<property>
	    <name>fs.defaultFS</name>
	    <value>hdfs://node1:8020</value>
	</property>

	<property>
	  <name>javax.jdo.option.ConnectionURL</name>
	  <value>jdbc:postgresql://node1/metastore</value>
	  <description>JDBC connect string for a JDBC metastore</description>
	</property>

	<property>
	  <name>javax.jdo.option.ConnectionDriverName</name>
	  <value>org.postgresql.Driver</value>
	  <description>Driver class name for a JDBC metastore</description>
	</property>

	<property>
	  <name>javax.jdo.option.ConnectionUserName</name>
	  <value>hiveuser</value>
	  <description>username to use against metastore database</description>
	</property>

	<property>
	  <name>javax.jdo.option.ConnectionPassword</name>
	  <value>redhat</value>
	  <description>password to use against metastore database</description>
	</property>

	<property>
	 <name>mapred.job.tracker</name>
	 <value>node1:8031</value>
	</property>

	<property>
	 <name>mapreduce.framework.name</name>
	 <value>yarn</value>
	</property>

	<property>
	    <name>datanucleus.autoCreateSchema</name>
	    <value>false</value>
	</property>

	<property>
	    <name>datanucleus.fixedDatastore</name>
	    <value>true</value>
	</property>

	<property>
	    <name>hive.metastore.warehouse.dir</name>
	    <value>/user/hive/warehouse</value>
	</property>

	<property>
	    <name>hive.metastore.uris</name>
	    <value>thrift://node1:9083</value>
	</property>

	<property>
	    <name>hive.metastore.local</name>
	    <value>false</value>
	</property>
	<property>
	  <name>hive.support.concurrency</name>
	  <description>Enable Hive's Table Lock Manager Service</description>
	  <value>true</value>
	</property>

	<property>
	  <name>hive.zookeeper.quorum</name>
	  <description>Zookeeper quorum used by Hive's Table Lock Manager</description>
	  <value>node2,node3,node1</value>
	</property>

	<property>
	  <name>hive.hwi.listen.host</name>
	  <value>node1</value>
	  <description>This is the host address the Hive Web Interface will listen on</description>
	</property>

	<property>
	  <name>hive.hwi.listen.port</name>
	  <value>9999</value>
	  <description>This is the port the Hive Web Interface will listen on</description>
	</property>

	<property>
	  <name>hive.hwi.war.file</name>
	  <value>lib/hive-hwi-0.10.0-cdh4.2.0.war</value>
	  <description>This is the WAR file with the jsp content for Hive Web Interface</description>
	</property>

	<property>
	  <name>hive.merge.mapredfiles</name>
	  <value>true</value>
	  <description>Merge small files at the end of a map-reduce job</description>
	</property>
	</configuration>


### 在hdfs中创建hive数据仓库目录

* hive的数据仓库在hdfs中默认为`/user/hive/warehouse`,建议修改其访问权限为1777，以便其他所有用户都可以创建、访问表，但不能删除不属于他的表。
* 每一个查询hive的用户都必须有一个hdfs的home目录(/user目录下，如root用户的为`/user/root`)
* hive所在节点的 /tmp必须是world-writable权限的。

	sudo -u hdfs hadoop fs -mkdir /user/hive/warehouse
	sudo -u hdfs hadoop fs -chown hive /user/hive/warehouse

### 启动hive

	service hive-metastore start
	service hive-server start
	service hive-server2 start

### 访问beeline

	$ /usr/lib/hive/bin/beeline
	beeline> !connect jdbc:hive2://localhost:10000 username password org.apache.hive.jdbc.HiveDriver
	0: jdbc:hive2://localhost:10000> SHOW TABLES;
	show tables;
	+-----------+
	| tab_name  |
	+-----------+
	+-----------+
	No rows selected (0.238 seconds)
	0: jdbc:hive2://localhost:10000> 

其 sql语法参考[SQLLine CLI](http://sqlline.sourceforge.net/)，在这里，你不能使用HiveServer的sql语句

### 与hbase集成
需要在hive里添加以下jar包：

	ADD JAR /usr/lib/hive/lib/zookeeper.jar;
	ADD JAR /usr/lib/hive/lib/hbase.jar;
	ADD JAR /usr/lib/hive/lib/hive-hbase-handler-0.10.0-cdh4.2.0.jar
	ADD JAR /usr/lib/hive/lib/guava-11.0.2.jar;


## 9. 参考文章

* [Creating a Local Yum Repository](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_30.html)
* [Java Development Kit Installation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_29.html)
* [Deploying HDFS on a Cluster](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_11_2.html)
* [HBase Installation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_20.html)
* [ZooKeeper Installation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_21.html)
* [hadoop cdh 安装笔记](http://roserouge.iteye.com/blog/1558498)