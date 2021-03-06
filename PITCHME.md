<style>
.reveal section img { background:none; border:none; box-shadow:none; }
</style>

## Optimizing Backup Performance
## Using Data Science Techniques

<a href="https://www.catallaxyservices.com">Kevin Feasel</a> (<a href="https://twitter.com/feaselkl">@feaselkl</a>)<br />
<a href="https://csmore.info/on/backups">https://CSmore.info/on/backups</a>

---

@title[Who Am I?]

[drag=60 100, drop=0 0]
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
<td><a href="https://www.apress.com/us/book/9781484254608"><img src="https://www.catallaxyservices.com/media/PolyBaseRevealed.png" height="153" width="107" /></a></td>
<td><a href="https://www.apress.com/us/book/9781484254608">PolyBase Revealed</a></td>
</tr>
</table>

[drag=40 100, drop=60 0]
![Kevin Feasel](https://www.catallaxyservices.com/media/HeadShot.jpg)

[@feaselkl](https://www.twitter.com/feaselkl)

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
3. Analysis
4. What's Next?

---?image=presentation/assets/background/problem.jpg&size=cover&opacity=20

### Describing the Problem

Backups (and restores) are critical for database administrators, but it can take a lot of time to back up a large database.

If you have a fixed amount of time to take backups, you might run into trouble as your databases grow.

---?image=presentation/assets/background/questions.jpg&size=cover&opacity=20

### What Can We Do?

@ul[list-fade-bullets]
* Use read-only filegroups.
* Use newer editions of SQL Server like 2017.
* Remove obsolete tables.
* Use data compression, columnstore indexes, etc. to reduce data size.
* Split data across multiple filegroups.
* Use differential backups between full backups.
* Configure backup settings.
@ul

---

@title[The Settings]

## Agenda

1. Describing the Problem
2. **The Settings**
3. Analysis
4. What's Next?

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

[drag=100 10, drop=0 0]
### Block Size

[drag=100 30, drop=0 10]
The physical block size. This really only matters for backup tapes and CD-ROMs but it is still settable.

[drag=50 50, drop=25 40, border=thick dotted black, bg=black, rotate=-5, animate=fadein slower]
Valid values: `{ 0.5kb, 1kb, 2kb, 4kb, 8kb, 16kb, 32kb, 64kb }`

---?image=presentation/assets/background/trains.jpg&size=cover&opacity=20

[drag=100 10, drop=0 0]
### Max Transfer Size

[drag=100 30, drop=0 10]
Maximum amount of data to be transferred per operation.  My working metaphor for this is a **bucket**.

[drag=60 60, drop=0 40, animate=fadein slower]
![A bucket](presentation/assets/image/Bucket.jpg)

[drag=50 50, drop=45 40, border=thick dotted black, bg=black, rotate=-5, animate=fadein slower]
Valid values: `{ 64kb, 128kb, 256kb, 512kb, 1mb, 2mb, 4mb }`

---?image=presentation/assets/background/buckets.jpg&size=cover&opacity=20

[drag=100 10, drop=0 0]
### Buffer Count

[drag=100 30, drop=0 10]
Number of buffers of size `MaxTransferSize` to be created.  In other words, the **number of buckets**.

[drag=50 30, drop=25 40, border=thick dotted black, bg=black, rotate=-5, animate=fadein slower]
Valid values: `{ 1:N }`

[drag=100 30, drop=0 70]
Try to stay at or below 1024.  With 1024 buffers * 4 MB Max Transfer Size, that's 4 GB of memory used for a single backup.

---?image=presentation/assets/background/folders.jpg&size=cover&opacity=20

[drag=100 10, drop=0 0]
### File Count

[drag=100 30, drop=0 10]
Tell SQL Server to stripe your backup across multiple files. This is a nice way of getting extra throughput out of your backups.

[drag=50 50, drop=25 40, border=thick dotted black, bg=black, rotate=-5, animate=fadein slower]
Valid values: `{ 1:N }`

---?image=presentation/assets/background/blue-package.jpg&size=cover&opacity=20

[drag=100 10, drop=0 0]
### Compression

[drag=100 30, drop=0 10]
Tell SQL Server whether or not you want to compress your backup. This has a very minor cost of CPU but typically leads to much smaller backups, so my default is to say yes.

[drag=50 50, drop=25 40, border=thick dotted black, bg=black, rotate=-5, animate=fadein slower]
Valid values: `{ TRUE, FALSE }`

---

### Coming up with New Settings

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
@[1-8](...but are these the right settings?)

---?image=presentation/assets/background/questions.jpg&size=cover&opacity=20

### What Should We Do?

Although we **can** change each of these settings, there are quite a few values.  Which ones should we choose?

That will depend on your hardware, workload, and other factors specific to your environment, so we won't come up with numbers which apply everywhere.

But what we **can** do is give you the tools necessary to determine what good settings look like in your environment.

---?image=presentation/assets/background/white-wall.jpg&size=cover&opacity=20

### The Power of Sampling

* Block Size: { 0.5kb, 1kb, 2kb, 4kb, 8kb, 16kb, 32kb, 64kb }
* Max Transfer Size: { 64kb, 128kb, 256kb, 512kb, 1mb, 2mb, 4mb }
* Buffer Count: { 7, 15, 30, 60, 128, 256, 512, 1024 }
* File Count: { 1, 2, 4, 6, 8, 10, 12 }
* Compression: { TRUE }

That gives us 3136 separate options.  At 10 minutes per backup, that's 31,360 minutes or ~22 days straight of backups.

---?image=presentation/assets/background/microscope2.jpg&size=cover&opacity=20

### Sampling with PowerShell

We can combine DBATools with simple PowerShell to perform sampling of these settings for our databases.  That way, we perform a tiny fraction of the total amount of work, but still generate enough results that we can speculate on how the full set would look.

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Analysis]

## Agenda

1. Describing the Problem
2. The Settings
3. **Analysis**
4. What's Next?

---

### Techniques

We want to solve a **regression** problem:  we have data with actual values and want to build a model which predicts based on inputs.  Examples of regression models include:

* Linear Regression
* Random forests and decision trees
* Neural network regression

---

### Linear Regression

![An example of linear regression](presentation/assets/image/LinearRegression.png)

---

### Decision Trees

![An example of a decision tree](presentation/assets/image/DecisionTree.png)

---

### Random Forest

![A dramatization of random forests.](presentation/assets/image/RandomForest.png)

---?image=presentation/assets/background/demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[What's Next?]

## Agenda

1. Describing the Problem
2. The Settings
3. Analysis
4. **What's Next?**

---?image=presentation/assets/background/construction.jpg&size=cover&opacity=20

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
<p>
	To learn more, go here:
	<br />
	<a href="https://csmore.info/on/backups">https://CSmore.info/on/backups</a>
</p>
<br />
<p>
	And for help, contact me:
	<br />
	<a href="mailto:feasel@catallaxyservices.com">feasel@catallaxyservices.com</a> | <a href="https://www.twitter.com/feaselkl">@feaselkl</a>
</p>
<br />
<p>
	Catallaxy Services consulting:
	<br />
	<a href="https://csmore.info/contact">https://CSmore.info/on/contact</a>
</p>
