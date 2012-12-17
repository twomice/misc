Command line utitlity to compile Kimai exported CSV data into
something more useful for me.

Call this script as follows:
$ php /path/to/hours-cleanup.php FILENAME

FILENAME: a CSV file exported from Kimai. This script checks the following
locations for this file, in this order, and uses the first matching file it
finds:
1. [no preceding path] -- as if the file were an absolute file path
2. the current working directory
3. /tmp


This script is written based on my working style with Kimai:
* Kimai "tasks" describe the type of work I'm doing, so I have only a few tasks,
such as:
    - Fixed-price work
    - Hourly work
    - Non-billable communications
    - Support contract
    - _general tasks  (the leading underscore on this one just to force it to
      sort last in the Kimai UI)

* Kimai "customers" are my own customers, whom I will be invoicing. My customers
include
    - MyCompany
    - Personal (I have this because I track time stuff that I'm doing for myself
      like homeschooling my kids, working out, mindless YouTube time, etc.)
    - Other shops I might work for (none currently)
    - Other direct consumer-level clients I might work for (none currently)

* Kimai "projects" are the clients of my customers. In Kimai, each Project
  belongs to exactly one Customer. So I have Projects for each Customer like this:
    - Customer: "MyCompany"
        - MyCompany (for MyCompany-specific work like strategy meetings,
          infrastructure, etc.)
        - American Widget Manufacturer's Alliance
        - National Campaign to Halt Widget Production
    - Customer: "Personal"
        - fitness
        - school
        - wasting time
    - Customer: "Other Shop I Might Work For"
        - Shop I Might Work For (for work done specifically for this client,
          like strategy meetings, infrastructure, etc.)
        - Client 1 of this Shop I Might Work For
        - Client 2 of this Shop I Might Work For
    - Customer: "Direct Consumer-Level Client I Might Work For"
        - Direct Consumer-Level Client I Might Work For (since all the work for
          this Customer will always be for them, this is the only Project
          configured for this Customer.)

But there's a catch. Obviously MyCompany wants to report well when invoicing
AWMA (American Widget Manufacturer's Alliance), so I need to tell them that I
spent 5.5 hours on the user permissions system, and 2.25 hours on the proposal
workflow system. With the above configuration, the only place left to record
this level of detail is in the comment for each time entry.  So to handle this,
I manually write whatever I'm doing in that comment, whether it's a short textual
description, a bug tracker ID, or something else.

Since entering a comment can be tedious for every time entry, I often leave the
comment blank, as long as I know it will just be the same as what I was doing in
the last entry for that project and task.

An example day might look like this:
- MyCompany: AWMA: Hourly work: "user permissions system improvements": Started at 9:11; Ended at 9:22 (Total time: 0:11)
- MyCompany: AWMA: Hourly work: "": Started at 10:07; Ended at 10:35 (Total time: 0:28)
- MyCompany: AWMA: Hourly work: "proposal workflow system mockups": Started at 9:23; Ended at 11:06 (Total time: 1:43)
- MyCompany: AWMA: Hourly work: "": Started at 13:12; Ended at 13:43 (Total time: 0:31)
- MyCompany: AWMA: Hourly work: "": Started at 14:16; Ended at 14:23 (Total time: 0:07)
- MyCompany: AWMA: Hourly work: "user permissions system improvements": Started at 15:08; Ended at 18:24 (Total time: 3:16)

All this script does is to 1) fill in any blank comments with the value of the
previous comment for that project/task, and then 2) compile all time entries
into single entries per day per project per task per comment, so times are
summed and we get entries like this:
- MyCompany: AWMA: Hourly work: "user permissions system improvements": Total time 3:55
- MyCompany: AWMA: Hourly work: "proposal workflow system mockups": Total time 2:21

I'm guessing this won't exactly fit anybody else's individual needs; but it
worked well for me for a couple of years, as I would use this step to get a
simple set of daily time entries so that I could show to each exactly how their
hours were used.
