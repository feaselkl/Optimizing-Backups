<style>
.reveal section img { background:none; border:none; box-shadow:none; }
</style>

## Optimizing Backup Performance Using Data Science Techniques

<a href="https://www.catallaxyservices.com">Kevin Feasel</a> (<a href="https://twitter.com/feaselkl">@feaselkl</a>)
<a href="https://csmore.info/on/backups">https://CSmore.info/on/backups</a>

---

@title[Who Am I?]

@div[left-60]
<table>
	<tr>
		<td><a href="https://csmore.info"><img src="https://www.catallaxyservices.com/media/Logo.png" height="133" width="119" /></a></td>
		<td><a href="https://csmore.info">Catallaxy Services</a></td>
	</tr>
	<tr>
		<td><a href="https://curatedsql.com"><img src="https://www.catallaxyservices.com/media/CuratedSQLLogo.png" height="133" width="119" /></a></td>
		<td><a href="https://curatedsql.com">Curated SQL</a></td>
	</tr>
	<tr>
		<td><a href="https://wespeaklinux.com"><img src="https://www.catallaxyservices.com/media/WeSpeakLinux.jpg" height="133" width="119" /></a></td>
		<td><a href="https://wespeaklinux.com">We Speak Linux</a></td>
	</tr>
</table>
@divend

@div[right-40]
	<br /><br />
	<a href="https://www.twitter.com/feaselkl"><img src="https://www.catallaxyservices.com/media/HeadShot.jpg" height="358" width="315" /></a>
	<br />
	<a href="https://www.twitter.com/feaselkl">@feaselkl</a>
</div>
@divend

---?image=presentation/assets/background/window.jpg&size=cover&opacity=20

### How Big is Your Backup Window?

How much time do you have to perform full backups?  Do you (or someone you know) want to reduce that window?

---?image=presentation/assets/background/motivation.jpg&size=cover&opacity=20

### Motivation

We will use data science techniques to minimize the amount of time it takes to back up our existing databases.

This will help us back up (and potentially restore) databases faster than the defaults would allow.

---

@title[Describing the Problem]

## Agenda

1. **Describing the Problem**
2. The Settings
3. Random Forest
4. Linear Regression
5. Training and Testing
6. Genetic Algorithms
7. What's Next?

---?image=presentation/assets/background/problem.jpg&size=cover&opacity=20

### Describing the Problem

Backups (and restores) are critical for database administrators, but it can take a lot of time to back up a large database.

If you have a fixed amount of time to take backups, you might run into trouble as your databases grow.

---?image=presentation/assets/background/questions.jpg&size=cover&opacity=20

### What Can We Do?

* Use read-only filegroups.
* Use newer editions of SQL Server like 2017.
* Remove obsolete tables.
* Use data compression, columnstore indexes, etc. to reduce data size.
* Split data across multiple filegroups.
* Use differential backups between full backups.
* Configure backup settings.  We'll do this!

---

@title[The Settings]

## Agenda

1. Describing the Problem
2. **The Settings**
3. Random Forest
4. Linear Regression
5. Training and Testing
6. Genetic Algorithms
7. What's Next?

---

### Backing Up a Database

The simplest settings:

```sql
BACKUP DATABASE [Scratch]
TO DISK = N'H:\Backups\Scratch.bak'
WITH NOFORMAT, INIT
GO
```

---?image=presentation/assets/background/blocks.jpg&size=cover&opacity=20

### Block Size

The physical block size. This really only matters for backup tapes and CD-ROMs but it is still settable.

Valid values: `{ 0.5kb, 1kb, 2kb, 4kb, 8kb, 16kb, 32kb, 64kb }`

---?image=presentation/assets/background/trains.jpg&size=cover&opacity=20

### Max Transfer Size

Maximum amount of data to be transferred per operation.

Valid values: `{ 64kb, 128kb, 256kb, 512kb, 1mb, 2mb, 4mb }`

---?image=presentation/assets/background/buckets.jpg&size=cover&opacity=20

### Buffer Count

Number of buffers of size `MaxTransferSize` to be created.

Valid values: `{ 1:N }`

Try to stay at or below 1024.  With 1024 buffers * 4 MB Max Transfer Size, that's 4 GB of memory used for a single backup.

---?image=presentation/assets/background/folders.jpg&size=cover&opacity=20

### File Count

Tell SQL Server to stripe your backup across multiple files. This is a nice way of getting extra throughput out of your backups.

Valid values: `{ 1:N }`

---?image=presentation/assets/background/blue-package.jpg&size=cover&opacity=20

### Compression

Tell SQL Server whether or not you want to compress your backup. This has a very minor cost of CPU but typically leads to much smaller backups, so my default is to say yes.

Valid values: `{ TRUE, FALSE }`

---

```sql
BACKUP DATABASE [Scratch]
	TO DISK = N'H:\Backup\Scratch1.bak',
	DISK = N'H:\Backup\Scratch2.bak'
WITH NOFORMAT, INIT,
	MAXTRANSFERSIZE = 2097152,
	BUFFERCOUNT = 50,
	BLOCKSIZE = 8192,
	COMPRESSION
```

@[2-3](Write to multiple files.)
@[5](Set the max trasnfer size to 2MB.)
@[6](Set the buffer count to 50.)
@[7](Set the block size to 8KB.)
@[8](Enable compression.)

---?image=presentation/assets/background/questions.jpg&size=cover&opacity=20

### What Should We Do?

Although we **can** change each of these settings, there are quite a few values.  Which ones should we choose?

That will depend on your hardware, workload, and other factors specific to your environment, so we won't come up with numbers which apply everywhere.

---?image=presentation/assets/background/white-wall.jpg&size=cover&opacity=20

### The Power of Sampling

* Block Size: { 0.5kb, 1kb, 2kb, 4kb, 8kb, 16kb, 32kb, 64kb }
* Max Transfer Size: { 64kb, 128kb, 256kb, 512kb, 1mb, 2mb, 4mb }
* Buffer Count: { 7, 15, 30, 60, 128, 256, 512, 1024 }
* File Count: { 1, 2, 4, 6, 8, 10, 12 }
* Compression: { TRUE }

That gives us 3136 separate options.  At 10 minutes per backup, that's 31,360 minutes or ~22 days staright of backups.

---?image=presentation/assets/background/microscope2.jpg&size=cover&opacity=20

### Sampling with PowerShell

We can combine DBATools with simple PowerShell to perform sampling of these settings for our databases.  That way, we perform a tiny fraction of the total amount of work, but still generate enough results that we can speculate on how the full set would look.

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Random Forest]

## Agenda

1. Describing the Problem
2. The Settings
3. **Random Forest**
4. Linear Regression
5. Training and Testing
6. Genetic Algorithms
7. What's Next?

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Linear Regression]

## Agenda

1. Describing the Problem
2. The Settings
3. Random Forest
4. **Linear Regression**
5. Training and Testing
6. Genetic Algorithms
7. What's Next?

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Training and Testing]

## Agenda

1. Describing the Problem
2. The Settings
3. Random Forest
4. Linear Regression
5. **Training and Testing**
6. Genetic Algorithms
7. What's Next?

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Genetic Algorithms]

## Agenda

1. Describing the Problem
2. The Settings
3. Random Forest
4. Linear Regression
5. Training and Testing
6. **Genetic Algorithms**
7. What's Next?

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[What's Next?]

## Agenda

1. Describing the Problem
2. The Settings
3. Random Forest
4. Linear Regression
5. Training and Testing
6. Genetic Algorithms
7. **What's Next?**

---?image=presentation/assets/background/sinkhole.jpg&size=cover&opacity=20

### What's Next?

What we've done so far:

* Look at a variety of databases
* Attempt to maximize performance using different algorithms

---?image=presentation/assets/background/engineering.jpg&size=cover&opacity=20

### What's Next?

Next steps:

* Reverse the process:  output parameters which maximize performance
* Deploy the model somewhere useful -- maybe using SQL Server ML Services
* Test results and eventually retrain your model

---?image=presentation/assets/background/wrappingup.jpg&size=cover&opacity=20

@title[Wrapping Up]

### Wrapping Up

Over the course of today's talk, we have covered one data science scenario, optimizing backups.  We tried several algorithms and approaches to solving this problem and saw how they compare.

---

### Wrapping Up

To learn more, go here:  <a href="https://csmore.info/on/backups">https://CSmore.info/on/backups</a>

And for help, contact me:  <a href="mailto:feasel@catallaxyservices.com">feasel@catallaxyservices.com</a> | <a href="https://www.twitter.com/feaselkl">@feaselkl</a>
