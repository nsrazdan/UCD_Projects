#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include "disk.h"
#include "fs.h"

#define FAT_ENTRIES_PER_BLOCK 2048
#define FAT_EOC 0xFFFF

/* Data structures in order to implement the various blocks
 * of the file system 
 */
struct superblock {
	char signature[8];
	uint16_t total_blocks;
	uint16_t root_index;
	uint16_t data_start_index;
	uint16_t total_data_blocks;
	uint8_t total_FAT_blocks;
	char padding[4079];
} __attribute__((__packed__));
typedef struct superblock* superblock_t;

struct metadata {
	char file_name[16];
	uint32_t file_size;
	uint16_t data_index;
	char padding[10];
} __attribute__((__packed__));
typedef struct metadata* metadata_t;

struct root {
	metadata_t files[FS_FILE_MAX_COUNT];
	uint16_t total_files;
} __attribute__((__packed__));
typedef struct root* root_t;

/* Struct to represent all open files 
 * User accesses by index which we return when they open file
 * Index of files and offset relate to same file (ie index 10 of offset will 
 * relate to offset of file open in index 10)
 */
struct file_descriptor_table {
	metadata_t files[FS_OPEN_MAX_COUNT];
	size_t offset[FS_OPEN_MAX_COUNT];
	int num_files_open;
};
typedef struct file_descriptor_table* file_descriptor_table_t;

/* Global variables */
superblock_t sb;
root_t root_directory;
file_descriptor_table_t fdt;
uint16_t* FAT;
uint16_t used_FAT_blocks;

/* Return -1 if superblock not in expected format. 0 otherwise */
int superblock_errors() {
	char signature[8] = "ECS150FS";
	
	/* Check signature */
	if (strncmp(signature, sb->signature, 8) != 0) return -1;
	
	/* Check blocks count */
	if (sb->total_blocks != block_disk_count()) return -1;
	
	/* Check root index */
	if (sb->root_index != 1 + sb->total_FAT_blocks) return -1;
	
	/* Check data start index*/
	if (sb->data_start_index != sb->root_index + 1) return -1;
	
	/* Check total number of data blocks */
	if (sb->total_data_blocks != sb->total_blocks - 
		sb->total_FAT_blocks - 2) return -1;
		
	/* Ensure the first block in the FAT is equal to FAT_EOC */
	if(FAT[0] != FAT_EOC) return -1;
	
	return 0;
}

/* Mount the virtual disk file by opening the file and
 * populating our data structures with information from the disk
 */
int fs_mount(const char *diskname)
{
	/* Initiliazing global vars */
	sb = malloc(sizeof(struct superblock));
	root_directory = malloc(sizeof(struct root));
	used_FAT_blocks = 0;

	/* Initialize file descriptor table to be entirely vacant */
	fdt = malloc(sizeof(struct file_descriptor_table));
	fdt->num_files_open = 0;
	for(int i = 0; i < FS_OPEN_MAX_COUNT; i++) {
		fdt->offset[i] = 0;
		fdt->files[i] = NULL;
	}
	
	/* Initialize file metadata structures */
	for (int i = 0; i < FS_FILE_MAX_COUNT; ++i) {
		root_directory->files[i] = malloc(sizeof(struct metadata));
		root_directory->files[i]->file_name[0] = '\0';
	}

	/* Open the virtual disk file, return error if
	 * block_disk_open returns an error
	 */
	if (block_disk_open(diskname) == -1) {
		return -1;
	}

	/* Read in superblock from the first block of the disk */
	char* temp_sb = malloc(sizeof(char) * BLOCK_SIZE);
	block_read(0, temp_sb);
	memcpy(sb->signature, &temp_sb[0], 8);
	memcpy(&sb->total_blocks, &temp_sb[8], 2);
	memcpy(&sb->root_index, &temp_sb[10], 2);
	memcpy(&sb->data_start_index, &temp_sb[12], 2);
	memcpy(&sb->total_data_blocks, &temp_sb[14], 2);
	memcpy(&sb->total_FAT_blocks, &temp_sb[16], 1);
	free(temp_sb);

	/* Allocate memory for FAT blocks*/
	FAT = malloc(sizeof(uint16_t) * sb->total_FAT_blocks * FAT_ENTRIES_PER_BLOCK);
	
	/* Read in data from disk and initialize FAT blocks */
	for (int i = 1; i < sb->total_FAT_blocks + 1; i++) {
		/* Read in one block */
		char data[BLOCK_SIZE];
		block_read(i, data);
		
		/* Separate block into FAT entries */
		for(int j = 0; j < FAT_ENTRIES_PER_BLOCK; j++) {
			memcpy(FAT + (i - 1) * FAT_ENTRIES_PER_BLOCK + j, data + (j * 2), 2);
		}
	}

	/* Iterate through the FAT array to get a count of how many
	 * FAT entries are used. This is to calculate the FAT ratio
	 * in fs_info()
	 */
	for (int i = 0; i < sb->total_data_blocks; ++i) {
		if (FAT[i] != 0) ++used_FAT_blocks;
	}

	/* Initialize root directory
	 * Create a temporary char* array to store the output from block_read,
	 * then parse the array file by file to sort the information into our
	 * metadata struct
	 */
	char* temp_root_array = malloc(sizeof(char) * BLOCK_SIZE);
	block_read(sb->root_index, temp_root_array);

	/* Now populate our root struct with the parsed information in our temp_root_array */
	int current_file_index = 0;
	for (int i = 0; i < BLOCK_SIZE; i += 32) {
		char temp_file_name[16];
		uint32_t temp_file_size;
		uint16_t temp_data_index;
		
		/* Split data into correct fields and read into related vars*/
		memcpy(temp_file_name, &temp_root_array[i + 0], 16);
		memcpy(&temp_file_size, &temp_root_array[i + 16], 4);
		memcpy(&temp_data_index, &temp_root_array[i + 20], 2);
		
		/* Copy data to root directory struct */
		strcpy(root_directory->files[current_file_index]->file_name, temp_file_name);
		root_directory->files[current_file_index]->file_size = temp_file_size;
		root_directory->files[current_file_index]->data_index = temp_data_index;
		
		/* Increment file counter if file is not empty */
		if(temp_file_name[0] != '\0') root_directory->total_files++;
		
		++current_file_index;
		continue;
	}
	

	/* Clear the memory allocated by temp_root_array*/
	free(temp_root_array);
	
	/* Check for errors in superblock formatting */
	return superblock_errors();
}

/* Unmount the current virtual disk and free memory allocated by structs
 * Make sure all metadata, the superblock, and root is saved
 */
int fs_umount(void)
{
	/* Check to see if a virtual disk was even opened */
	if (block_disk_count() == -1) {
		return -1;
	}

	/* Return error if there are open files in the fdt */
	if (fdt->num_files_open > 0) {
		return -1;
	}

	/* Save superblock information to the disk */
	unsigned char* sb_byte_array = malloc(BLOCK_SIZE);
	memcpy(sb_byte_array, (const unsigned char*)sb, BLOCK_SIZE);
	block_write(0, sb_byte_array);

	/* Save root directory information to the disk by copying
	 * metadata information into a local struct
	 */
	struct metadata temp_files[FS_FILE_MAX_COUNT];
	for (int i = 0; i < FS_FILE_MAX_COUNT; i++) {
		temp_files[i] = *root_directory->files[i];
	}
	int root_dir_size = sizeof(struct metadata) * FS_FILE_MAX_COUNT;
	unsigned char* root_byte_array = (unsigned char*) malloc(root_dir_size);
	memcpy(root_byte_array, (const unsigned char*)temp_files, root_dir_size);
	block_write(sb->root_index, root_byte_array);

	/* Save FAT information to disk */
	for(int i = 0; i < sb->total_FAT_blocks; i++) {
		unsigned char* fat_byte_array = malloc(BLOCK_SIZE);
		memcpy(fat_byte_array, (const unsigned char*)FAT + i * BLOCK_SIZE, BLOCK_SIZE);
		block_write(i + 1, fat_byte_array);
	}
	
	/* Free all the allocated memory from the data structures */
	for (int i = 0; i < FS_FILE_MAX_COUNT; ++i) {
		free(root_directory->files[i]);
	}

	free(root_directory);
	free(FAT);
	free(sb);
	free(fdt);
	
	/* Close virtual disk, if it returns an error, then return -1 */
	if (block_disk_close() == -1) {
		return -1;
	}

	return 0;

}

/* Print to the screen all the necessary information about the virtual disk file
 * All this information is read right from the superblock
 */
int fs_info(void)
{
	/* Check to see if a virtual disk was even opened */
	if (block_disk_count() == -1) {
		return -1;
	}

	/* Calculate the ratio values, as shown in fs_ref.x */
	uint16_t fat_ratio = sb->total_data_blocks - used_FAT_blocks;
	uint16_t file_free_ratio = FS_FILE_MAX_COUNT - root_directory->total_files;

	/* Print all the info that's required, used fs_ref.x as
	 * an example as to what we needed to print
	 */
	printf("FS Info:\n");
	printf("total_blk_count=%u\n", sb->total_blocks);
	printf("fat_blk_count=%u\n", sb->total_FAT_blocks);
	printf("rdir_blk=%u\n", sb->root_index);
	printf("data_blk=%u\n", sb->data_start_index);
	printf("data_blk_count=%u\n", sb->total_data_blocks);
	printf("fat_free_ratio=%u/%u\n", fat_ratio, sb->total_data_blocks);
	printf("rdir_free_ratio=%u/%u\n", file_free_ratio, FS_FILE_MAX_COUNT);

	return 0;
}

int fs_create(const char *filename)
{
	/* Check to make sure that a virtual disk is mounted, if not
	 * throw an error.
	 */
	if (block_disk_count() == -1) return -1;

	/* Throw an error if filename is too long */
	if (strlen(filename) > FS_FILENAME_LEN) return -1;

	/* Throw an error if the string is empty */
	if (strcmp (filename, "") == 0) return -1;

	/* Throw error if maximum number of files reached */
	if (root_directory->total_files >= FS_FILE_MAX_COUNT) return -1;
	
	/* Iterate through the root directory to find an empty file space
	 * Once found, set the metadata's file name to filename
	 */
	int free_idx = -1;
	for (int i = 0; i < FS_FILE_MAX_COUNT; ++i) {
		if (root_directory->files[i]->file_name[0] == '\0') {
			strcpy(root_directory->files[i]->file_name, filename);
			root_directory->files[i]->file_size = 0;
			free_idx = i;
			break;
		}
	}
	
	/* If no free entry, return error */
	if (free_idx == -1) return -1;
	
	/* Find first free data block using FAT */
	for(int j = 0; j < sb->total_data_blocks; j++) {
		if(FAT[j] == 0) {
			FAT[j] = FAT_EOC;
			root_directory->files[free_idx]->data_index = j;
			break;
		}
	}

	/* Increment total files for future reference */
	++root_directory->total_files;

	return 0;
}

int fs_delete(const char *filename)
{
	/* Check to make sure that a virtual disk is mounted, if not
	 * throw an error.
	 */
	if (block_disk_count() == -1) {
		return -1;
	}

	/* Iterate through root directory to find file to delete
	 * Use the data start index to find the blocks to clear
	 * Then change file size to 0
	 * Mark start index as FAT_EOC
	 * Set file name to NULL and return 0
	 */
	for (int i = 0; i < FS_FILE_MAX_COUNT; ++i) {
		if (strcmp(root_directory->files[i]->file_name, filename) == 0) {
			uint16_t block_index = root_directory->files[i]->data_index;

			/* Reset all the FAT blocks taken by the file to 0 */
			while (FAT[block_index] != FAT_EOC) {
				uint16_t next = block_index;
				FAT[block_index] = 0;
				block_index = next;
				used_FAT_blocks--;
			}

			/* Reset last block from FAT_EOC to 0 to indicate that it is free */
			FAT[block_index] = 0;
			used_FAT_blocks--;

			/* Reset the file size to 0 and the file name to NULL, indicating
			 * the file has been deleted and the space is ready for a new file 
			 */
			root_directory->files[i]->file_size = 0;
			root_directory->files[i]->file_name[0] = '\0';
			--root_directory->total_files;
			return 0;
		}
	}

	/* Return -1 if there was no such filename found */
	return -1;
}

int fs_ls(void)
{
	/* Check to make sure that a virtual disk is mounted, if not
	 * throw an error
	 */
	if (block_disk_count() == -1) {
		return -1;
	}

	printf("FS Ls:\n");
	for (int i = 0; i < FS_FILE_MAX_COUNT; ++i) {
		if (root_directory->files[i]->file_name[0] != '\0') {
			printf("file: %s, ", root_directory->files[i]->file_name);
			printf("size: %d, ", root_directory->files[i]->file_size);
			printf("data_blk: %d\n", root_directory->files[i]->data_index);
		}
	}
	return 0;
}

/* Open file with filename and return file descriptor */
int fs_open(const char *filename)
{
	/* Return error if no available spot for new file */
	if(fdt->num_files_open == FS_OPEN_MAX_COUNT) return -1;
	
	/* Find file with filename. If none, return error. */
	metadata_t file_p;
	bool file_found = false;
	
	for(int i = 0; i < FS_FILE_MAX_COUNT; i++) {
		if(strcmp(root_directory->files[i]->file_name, filename) == 0) {
			file_found = true;
			file_p = root_directory->files[i];
		}
	}
	
	if(!file_found) return -1;
	
	/* Put pointer to file in first open index in fdt */
	int file_index = -1;
	
	for(int i = 0; i < FS_OPEN_MAX_COUNT; i++) {
		if(fdt->files[i] == NULL) {
			file_index = i;
			fdt->files[i] = file_p;
			fdt->offset[i] = 0;
		}
	}
	
	/* Increment num files open in fdt */
	fdt->num_files_open++;
	
	/* Return index with file in fdt */
	return file_index;
}

/* Close file with matching file descriptor */
int fs_close(int fd)
{
	/* Return error if fd is invalid */
	if (fd < 0 || fd >= FS_OPEN_MAX_COUNT) return -1;

	/* Return error is file doesn't exist */
	if (fdt->files[fd] == NULL) return -1;
	
	/* If no error, then clear file from fdt and decrement num_files_open */
	fdt->files[fd] = NULL;
	fdt->offset[fd] = 0;
	fdt->num_files_open--;
	
	return 0;
}

int fs_stat(int fd)
{
	/* Return error if fd is invalid */
	if (fd < 0 || fd >= FS_OPEN_MAX_COUNT) return -1;

	/* Return error is file doesn't exist */
	if (fdt->files[fd] == NULL) return -1;
	
	/* Get and return size */
	int size = (int)fdt->files[fd]->file_size;
	
	return size;
}

int fs_lseek(int fd, size_t offset)
{
	/* Return error if fd is invalid */
	if (fd < 0 || fd >= FS_OPEN_MAX_COUNT) return -1;

	/* Return error is file doesn't exist */
	if (fdt->files[fd] == NULL) return -1;
	
	/* Return error if offset is invalid */
	if (offset < 0 || offset > (size_t)fdt->files[fd]->file_size) return -1;
	
	/* Set offset */
	fdt->offset[fd] = offset;
	
	return 0;
}

void allocate_blocks(uint16_t block_index, size_t num_new_blocks) {
	/* Get to last index of file data */
	while(FAT[block_index] != FAT_EOC) {
		block_index = FAT[block_index];
	}
	
	/* Allocate new blocks */
	for(size_t i = 0; i < num_new_blocks; i++) {
		/* Find first empty block */
		int free_idx = -1;
		for(int j = 0; j < sb->total_data_blocks; j++) {
			if(FAT[j] == 0) {
				free_idx = j;
				break;
			}
		}
		
		/* Throw assertion if no free blocks found */
		assert(free_idx != -1);
		
		/* Set last FAT block to point to free block */
		FAT[block_index] = free_idx;
		
		/* Set block index to free index to allocate next block */
		block_index = free_idx;
		
		/* Set free index contents to end of chain in case we are not
		 * allocating any more blocks
		 */
		FAT[block_index] = FAT_EOC;
	}
}

int fs_write(int fd, void *buf, size_t count)
{
	/* Return error if fd is invalid */
	if (fd < 0 || fd >= FS_OPEN_MAX_COUNT) return -1;

	/* Return error is file doesn't exist */
	if (fdt->files[fd] == NULL) return -1;
	
	/* Get file */
	metadata_t file = fdt->files[fd];
	
	/* Check if count + offset > file size, meaning not enough memory allocated
	 * If so, then allocate new blocks
	 */
	if (count + fdt->offset[fd] > fdt->files[fd]->file_size) {
		/* Calculate number of new blocks to allocate */
		size_t num_new_bytes = count + fdt->offset[fd] -
			fdt->files[fd]->file_size;
		size_t num_new_blocks = (BLOCK_SIZE + num_new_bytes - 1) / BLOCK_SIZE;
		
		/* Check if the file is empty. If so, it already has a block allocated
		 * for it.
		 */
		if (fdt->files[fd]->file_size == 0) {
			num_new_blocks--;
		}
		
		/* Allocate new blocks */
		allocate_blocks(fdt->files[fd]->data_index, num_new_blocks);
		
		/* Update file size */
		fdt->files[fd]->file_size += count;
	}
	
	/* Get number of blocks the file contains */
	int num_blocks = ((int)file->file_size + BLOCK_SIZE - 1) / BLOCK_SIZE;
	
	/* Get array to hold all data of file */
	char data[num_blocks * BLOCK_SIZE];
	
	/* Read all data from blocks into array */
	size_t read_index = (size_t)file->data_index;
	
	for(int i = 0; i < num_blocks; i++) {
		/* Make temp buffer and read in data */
		char temp[BLOCK_SIZE];
		block_read(read_index + sb->data_start_index, &temp);
		
		/* Append temp to data array */
		strcat(data, temp);
		
		/* Get next index */
		read_index = (size_t) FAT[(int)read_index];
	}
	
	/* Replace data in array in written chunk with buffer */
	memcpy(data + fdt->offset[fd], buf, count);
	
	/* Write all data back to respective blocks */
	size_t write_index = (size_t)file->data_index;
	
	for(int i = 0; i < num_blocks; i++) {
		block_write(write_index + sb->data_start_index, data + i * BLOCK_SIZE);
	}
	
	/* Update offset */
	fdt->offset[fd] += count;

	return count;
}

int fs_read(int fd, void *buf, size_t count)
{
	/* Return error if fd is invalid */
	if (fd < 0 || fd >= FS_OPEN_MAX_COUNT) return -1;

	/* Return error is file doesn't exist */
	if (fdt->files[fd] == NULL) return -1;
	
	/* Get file */
	metadata_t file = fdt->files[fd];
	
	/* Get number of blocks the file contains */
	int num_blocks = ((int)file->file_size + BLOCK_SIZE - 1) / BLOCK_SIZE;
	
	/* Get array to hold all data of file */
	char data[num_blocks * BLOCK_SIZE];
	
	/* Read all data from blocks into array */
	size_t read_index = (size_t)file->data_index;
	
	for(int i = 0; i < num_blocks; i++) {
		/* Make temp buffer and read in data */
		char temp[BLOCK_SIZE];
		block_read(read_index + sb->data_start_index, &temp);
		
		/* Append temp to data array */
		strcat(data, temp);
		
		/* Get next index */
		read_index = (size_t) FAT[(int)read_index];
	}
	
	/* Get number of bytes to read after offset */
	size_t num_bytes_read;
	if((int)fdt->offset[fd] + (int)count > (int)file->file_size) {
		num_bytes_read = (size_t)file->file_size - fdt->offset[fd];
	} else {
		num_bytes_read = count;
	}
	
	/* Copy read data to buffer */
	memcpy(buf, data + fdt->offset[fd], num_bytes_read);
	
	/* Update offset */
	fdt->offset[fd] += num_bytes_read;
	
	/* Return number of bytes read */
	return num_bytes_read;
}

