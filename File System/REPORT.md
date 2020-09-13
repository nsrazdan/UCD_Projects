# Report on Project 4 - File System
by Edric Tom and Nikhil Razdan
***
## (I) Phase 0 - Skeleton Code
Used basic linux commands (sftp, ssh, cp, cd, get, etc.) to copy over
the skeleton code in order to begin the project.
***
## (II) Phase 1 - Mounting/unmounting
### Makefile
In this phase, we modified our Makefile from Programs 2 and 3 in order to be
compatible with the **libfs** library. This just involved changing a few
variables to reflect the files **disk** and **fs**.

### Mounting
After reading the instructions for this phase, we figured that we
needed to start with building our data structures. We began with the
**superblock**. Luckily the prompt basically spelled out exactly what needed to
go in this struct, so we populated the struct based on the tables provided
in the prompt (signature, indexes, and total values). From there, we
created the **metadata** struct, where the root directory would have an array
of these structs in order to keep track of file names, file sizes, and data
start blocks. Once we had these, we went on to create the **root directory**
struct itself, which only consisted of an array of 128 pointers to metadata
objects and a count of how many files there were in the directory. We
struggled for a bit on how to implement the FAT (file allocation table)
structure. We first created a struct, but then realized that was not the
way to go. We then created a 2D array, however, after coding most of the
project, we realized that was definitely not the way to go. We settled on
exactly what the prompt said, a one dimensional array. This was difficult
to work with, as we can only read in one block at a time from the disk and
there could be multiple FAT blocks, yet we only had one array. We
eventually figured out the algorithm to read in each block into the same
array. From there, we set global variables for the **superblock**, the **root**
directory, and the **FAT** structure. We also kept a global variable to
calculate how many data blocks were utilized in order to calculate
**fs_info**. Another quick note is that we realized late in the game how
useful **memcpy** was. Once we figured out we could convert whole structs
into bytes and then write the result of that onto the disk, we implemented
it in our functions and everything began to come together smoothly after that.

### fs_mount
This function gave us the most problems in this phase. We calculated the 
values that the superblock should have instead of just reading it in 
from the disk at first. However, in the latter phases of our project, 
we quickly fixed that issue. We began the function by allocating memory 
for each of our global variables and any of the arrays within those
structs. From there, we opened the disk and checked to make sure that it
did not return any errors. Then we read in the superblock from the disk and
made sure that it was formatted correctly, returning an error in case it
did not. From there we allocated memory for the FAT structure, which
definitely took us some time to figure out. After that, we read the
root directory from the disk and populated our structures based on what was
read. After that, we just returned the function. Figuring all of this out
definitely was the function that took us the most time in order to get
right. Especially after discovering the versatility of **memcpy** in order
to read in the various blocks from the disk, our lives became a lot
simpler.

### fs_unmount
This function was interesting in such a way where we implemented the first
parts of it (the error checking) and the final part of it (freeing the
different structures we allocated) and left it that way for some time. It
was only after we got to phase 3 that we realized how we had to save our
structures back to the disk (using **memcpy**). We quickly implemented the
"save" function of **fs_unmount** for the root directory and the
superblock. It was only after debugging our **fs_write** for an hour did we
realize we forgot to save the **FAT** blocks too. So we spent some time
implementing that for an hour.

### fs_info
This was the easiest function to write. Once we got all of the printf's
down, we focused on making the ratios that **fs_ref** displayed, which took
some tweaking as we went through our project and continued our
implementation. Overall though, this function caused little to no issues.
***

## (III) Phase 2 - File creation/deletion
### fs_create
File creation, or **fs_create**, actually did not take us much time to
implement. We did it while working on phase 1 so that we completed both
phases roughly around the same time. The prompt and
**fs.h** explained file creation pretty well. We knew that we had to start
off with our error checking, because there's no point in proceeding with
the rest of the function if the user did not pass in a valid **filename**.
From there, we first iterated through the root directory in order to find
an empty metadata struct in order to place our new file in (we found this
by setting the first character of the metadata's **file_name** to **\0**).
After we found an empty space (or returned an error due to the directory
being full), we would copy **filename** to the metadata struct and set the
**file size** equal to 0. After setting all that, we proceeded to find the
first **FAT block** that was initialized to 0, meaning that it was free and
not taken by any other files. We set **data_index** to the index of that
entry, initalized that FAT entry to be **FAT_EOC**, meaning that it was
the block that contained the end of the file, and returned out of the 
function.

### fs_delete
To implement file deletion, we simply did the reverse of everything that we
wrote in **fs_create**. However, we ran into some speed bumps where we had
to make sure that if a file had multiple data blocks allocated for it, that
we would set the additional FAT entries equal to 0 (indicating that they are
free for the file system to use) before setting the initial FAT block equal
to **FAT_EOC**. This took some time to debug but after a few minutes, we
were able to figure it out. However, this was the only limitation. We began
the function with typical error checking. Then we'd iterate through the
root directory to find the file that needs to be deleted (or return an
error if that file was not found). We used a while loop to set all the
additional FAT entries to 0, then set the initial data index to
**FAT_EOC**. We'd decrement our counter of FAT blocks used and from there
set the file size to 0 and the first character of the file name back to the
NULL character, indicating that it is a free spot in the **root directory** to
be used by another file.

### fs_ls
This function was just as simple as fs_info to implement. However, we
implemented it incorrectly at first because of the fact that we didn't test
the funciton with **fs_ref** before writing it. But once we saw the
reference program, we were able to quickly adapt our function to fit the
output. To implement this function, we merely iterated through our root
directory, skipping any null entries, and printed each file's **file_name**,
**file_size**, and **data_start_index**. We'd then just return. Of course,
we did begin the function with simple error checking as well, such as if a
disk was even mounted to begin with.
***

## (IV) Phase 3 - File descriptor operations
### file_descriptor_table struct
The majority of this phase centered around the creation, iniatializition,
and use of our **file_descriptor_table** struct. It contains a list of
pointers to files contained within our **root_directory** that are
currently opened, and their respective offsets. We decided not to create a
struct to represent a file descriptor for each individual file and instead
used an array of **metadata** pointers and size_t representing their
respective **offset**. This simplified our approach, as we could index both
using the **fd** of a given file.

### fs_open
This function was fairly simple for us to write. We began by checking for
errors, to make sure that there was a file to be found or if there are too
many files open at once. Once we found the file that we were looking for,
we created a variable that contained the pointer to the file and placed it
in an empty spot in the file descriptor table. We also initialized the
offset value for this file to 0, so that when **fs_read** is called on it
for the first time, it would start reading from the beginning of the file.
After that, we just returned from the function. fs_open was very
straight-forward for us to figure out, once we figured out how to implement
the struct for the file descriptor table of course.

### fs_close
This function was also quite simple. We began by error checking to make
sure that the file descriptor table was not empty and that the file
referenced at a certain file descriptor even existed. From there, all we
did was set the pointer at the file descriptor's index within the file
descriptor table to **null**, reset the offset to 0, and decremented our
counter for the number of files open. That function was not bad at all to
implement.  

### fs_stat
This function was also very easy to implement. All we did was check to make
sure the file existed or if the file descriptor table was not empty or
full, then just used the file descriptor passed into the function as the
index and copied over the file size of the file referenced. We returned
that value and that function was complete. Super easy to implement.

### fs_lseek
This function was simple. All we did was error checked (the usual culprits,
if the file was existed or if the descriptor was invalid), and then set the
offset that was passed to the function to the offset value for that
specific file descriptor. Nothing too bad. We did add an extra error check
however, to make sure that the offset was valid and within range of the
data blocks. 
***

## (V) Phase 4 - File reading/writing
### Implemention
For **fs_read** and **fs_write**, my strategy was to read all the data from
the file into one array, and perform the operation desired by the caller
with that array. This, I thought, would offer a cleaner and clearer
implementation. After completing read and most of write, I realized that,
although perhaps cleaner, my implementation would increase both the space
and time complexity of the read and write operations, as we would have to
read all the data instead of just the parts relevant to our operation. This
is very non-ideal, as reading and writing to a disk is already quite slow.
However, it was too complex to refractor with all the code written, so we
continued with my implementation.

### fs_read
For **fs_read**, we read all the information belonging to the file and
copied all **count** bytes starting at **offset** into **buffer**. However,
there is an edge case where the file reaches the end before **count** bytes
are read. To handle this edge case, we checked before reading if we would
reach the end before completing our read. If so, we just read to the end of
the file instead.

### fs_write
This was by far the most complex function to write in our program, as there
are many cases you must support. To solve the problem of writing into
partial blocks, we did the same thing with read and stored the file data in
an arrray. Then we used **memcpy** to write the **buffer** into the array
starting at **offset** for **count** bytes. This made our implemention much
easier, as we did not have to worry about which block we were in when
writing.

The much more difficult edge case arises when we do not have enough space
allocated for our file. This occurs when **count** + **offset** is greater
than **file_size**, meaning that the ending byte is past the limit of our
file. To solve this, we created a helper function **allocate_blocks** which
extended the FAT indices for our file. 

After writing to the array and potentially allocating new blocks, we simply
wrote the array back into the blocks, separating the array by
**BLOCK_SIZE**.
***

## (VI) Conclusion
All in all, this project was shockingly not as bad as we thought.
Considering the fact that we finished the project mere minutes before the
deadline and we really started working on it only 2 day prior to the due
date, we think that we did very well. After understanding how the different
data structures work together, how the block API that was provided to us
worked, and how **memcpy** was our lifesaver, we were able to basically
write the whole program in a day. Most of our time was spent debugging,
as usual with programs this large. We were unable to do extensive testing
due to our time crunch, but we did make massive use of
**test_fs_student.sh** (the grading shell script) and **fs_ref** in order
to make sure that our output was the same as the professor's. 
***
## (VII) Resources
- [GNU Manual](https://www.gnu.org/software/libc/manual/)
- [C reference](https://en.cppreference.com/w/c)