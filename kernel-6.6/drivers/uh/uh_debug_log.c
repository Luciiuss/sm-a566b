#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/highmem.h>
#include <linux/uh.h>
#include <linux/mutex.h>

#if (!IS_ENABLED(CONFIG_SEC_FACTORY)) && IS_ENABLED(CONFIG_UH)

unsigned long uh_log_paddr = 0xc1500000;
unsigned long uh_log_size = 0x3f000;

static DEFINE_MUTEX(uh_mutex);

static ssize_t uh_log_read(struct file *filep, char __user *buf, size_t size, loff_t *offset)
{
	static size_t log_buf_size;
	unsigned long *log_addr = 0;

	if (!strcmp(filep->f_path.dentry->d_iname, "uh_log"))
		log_addr = (unsigned long *)phys_to_virt(uh_log_paddr);
	else
		return -EINVAL;

	/* To print s2 table status */
	uh_call(UH_PLATFORM, 13, 0, 0, 0, 0);

	if (!mutex_trylock(&uh_mutex)) {
		pr_err("uh_log: Busy.\n");
		mutex_unlock(&uh_mutex);
		return -EBUSY;
		}

	if (!*offset) {
		log_buf_size = 0;
		while (log_buf_size < uh_log_size && ((char *)log_addr)[log_buf_size] != 0)
			log_buf_size++;
	}

	if (*offset >= log_buf_size) {
		mutex_unlock(&uh_mutex);
		return 0;
	}

	if (*offset + size > log_buf_size)
		size = log_buf_size - *offset;

	if (copy_to_user(buf, (const char *)log_addr + (*offset), size)) {
		mutex_unlock(&uh_mutex);
		return -EFAULT;
	}

	*offset += size;
	mutex_unlock(&uh_mutex);
	return size;
}

static const struct proc_ops uh_proc_ops = {
	.proc_read		= uh_log_read,
};
#endif // !(CONFIG_SEC_FACTORY) && (CONFIG_UH)

static int __init uh_log_init(void)
{
#if (!IS_ENABLED(CONFIG_SEC_FACTORY)) && IS_ENABLED(CONFIG_UH)
	struct proc_dir_entry *entry;
	mutex_init(&uh_mutex);

	entry = proc_create("uh_log", 0644, NULL, &uh_proc_ops);
	if (!entry) {
		pr_err("uh_log: Error creating proc entry\n");
		return -ENOMEM;
	}

	pr_info("uh_log : create /proc/uh_log\n");
	//uh_call(UH_PLATFORM, 0x5, (u64)&uh_log_paddr, (u64)&uh_log_size, 0, 0);
	pr_info("uh_log : create /proc/uh_log, %ld, %ld\n", uh_log_paddr, uh_log_size);
#endif
	
    return 0;
}

static void __exit uh_log_exit(void)
{
#if (!IS_ENABLED(CONFIG_SEC_FACTORY)) && IS_ENABLED(CONFIG_UH)
	mutex_destroy(&uh_mutex);
	remove_proc_entry("uh_log", NULL);
#endif
}

module_init(uh_log_init);
module_exit(uh_log_exit);
MODULE_LICENSE("GPL v2");
