/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * drivers/debug/sec_debug_internal.h
 *
 * COPYRIGHT(C) 2020 Samsung Electronics Co., Ltd. All Right Reserved.
 *
 */

#ifndef __SEC_DEBUG_INTERNAL_H__
#define __SEC_DEBUG_INTERNAL_H__

#include <linux/sizes.h>
#include <linux/sec_debug_built.h>

/* Watchdog driver data */
struct watchdogd_info {
	struct task_struct *tsk;
	struct thread_info *thr;
	struct rtc_time *tm;

	unsigned long long last_ping_time;
	int last_ping_cpu;
	bool init_done;

	unsigned long emerg_addr;
};

struct bad_stack_info {
	unsigned long magic;
	unsigned long esr;
	unsigned long far;
	unsigned long spel0;
	unsigned long cpu;
	unsigned long tsk_stk;
	unsigned long irq_stk;
	unsigned long ovf_stk;
};

struct suspend_dev_info {
	uint64_t suspend_func;
	uint64_t suspend_device;
	uint64_t shutdown_func;
	uint64_t shutdown_device;
};

struct sec_debug_kernel_data {
	uint64_t task_in_pm_suspend;
	uint64_t task_in_sys_reboot;
	uint64_t task_in_sys_shutdown;
	uint64_t task_in_dev_shutdown;
	uint64_t task_in_sysrq_crash;
	uint64_t task_in_soft_lockup;
	uint64_t cpu_in_soft_lockup;
	uint64_t task_in_hard_lockup;
	uint64_t cpu_in_hard_lockup;
	uint64_t unfrozen_task;
	uint64_t unfrozen_task_count;
	uint64_t sync_irq_task;
	uint64_t sync_irq_num;
	uint64_t sync_irq_name;
	uint64_t sync_irq_desc;
	uint64_t sync_irq_thread;
	uint64_t sync_irq_threads_active;
	uint64_t dev_shutdown_start;
	uint64_t dev_shutdown_end;
	uint64_t dev_shutdown_duration;
	uint64_t dev_shutdown_func;
	unsigned long sysrq_ptr;
	struct watchdogd_info wddinfo;
	struct bad_stack_info bsi;
	struct suspend_dev_info sdi;
};

/* some buffers to use in sec debug module */
enum sdn_map {
	SDN_MAP_DUMP_SUMMARY,
	SDN_MAP_AUTO_COMMENT,
	SDN_MAP_EXTRA_INFO,
	SDN_MAP_AUTO_ANALYSIS,
	SDN_MAP_INITTASK_LOG,
	SDN_MAP_DEBUG_PARAM,
	SDN_MAP_FIRST2M_LOG,
	SDN_MAP_SPARED_BUFFER,
	NR_SDN_MAP,
};

struct sec_debug_memtab {
	uint64_t table_start_pa;
	uint64_t table_end_pa;
	uint64_t reserved[4];
};

/*
 * SEC DEBUG AUTO COMMENT
 */
#define SEC_DEBUG_AUTO_COMM_BUF_SIZE 10

struct sec_debug_auto_comm_buf {
	int reserved_0;
	int reserved_1;
	int reserved_2;
	unsigned int offset;
	char buf[SZ_4K];
};

struct sec_debug_auto_comment {
	int header_magic;
	int fault_flag;
	int lv5_log_cnt;
	u64 lv5_log_order;
	int order_map_cnt;
	int order_map[SEC_DEBUG_AUTO_COMM_BUF_SIZE];
	struct sec_debug_auto_comm_buf auto_comm_buf[SEC_DEBUG_AUTO_COMM_BUF_SIZE];

	int tail_magic;
};

/*
 * SEC DEBUG GEN3 (Compatible with SEC DEBUG NEXT)
 */
#define LEN_SECDBG_OFFSET_NAME		(64)

#define NR_GEN3_LOGBUF		32

#define LEN_LOGBUF_NAME	(32)
/* LV2 (under secdbg_logbuf_list) */
struct secdbg_logbuf {
	uint64_t base;
	uint64_t size;
	char name[LEN_LOGBUF_NAME];
	uint32_t is_storage;
	uint32_t offset;
	uint32_t partition;
};

/* LV1 */
struct secdbg_logbuf_list {
	struct secdbg_logbuf data[NR_GEN3_LOGBUF];

	char name[LEN_SECDBG_OFFSET_NAME];
};

/* LV1 */
struct secdbg_memtab {
	struct sec_debug_memtab data;

	char name[LEN_SECDBG_OFFSET_NAME];
};

/* Offset for LV1 */
struct secdbg_lv1_member {
	char name[LEN_SECDBG_OFFSET_NAME];
	uint64_t size;
	uint64_t addr;
};

enum gen3_lv1_item {
	SDN_LV1_LOGBUF_MAP,
	SDN_LV1_MEMTAB,
	SDN_LV1_KERNEL_SYMBOL,
	SDN_LV1_KERNEL_CONSTANT,
	SDN_LV1_TASK_STRUCT,
	SDN_LV1_SNAPSHOT,
	SDN_LV1_SPINLOCK,	/* reserved */
	SDN_LV1_KERNEL_DATA,
	SDN_LV1_AUTO_COMMENT,
	SDN_LV1_EXTRA_INFO,
};

/* SEC DEBUG NEXT DEFINITION */
struct sec_debug_gen3 {
	unsigned int magic[2];
	unsigned int version[2];
	unsigned int used_offset;
	unsigned int end_addr;
	unsigned int reserved[4];

	struct secdbg_lv1_member lv1_data[64];
};

struct sec_debug_base_param {
	void *sdn_vaddr;
	bool init_sdn_done;
};

extern void *secdbg_base_built_get_debug_base(int type);
extern unsigned long secdbg_base_built_get_buf_base(int type);
extern void *secdbg_base_built_get_ncva(unsigned long pa);

#if IS_ENABLED(CONFIG_SEC_DEBUG_AUTO_COMMENT)
extern int secdbg_comm_auto_comment_init(void);
#else
static inline int secdbg_comm_auto_comment_init(void)
{
	return 0;
}
#endif /* CONFIG_SEC_DEBUG_AUTO_COMMENT */

/* sec_debug_memtab_built.c */
#if IS_ENABLED(CONFIG_SEC_DEBUG_MEMTAB)
extern void secdbg_base_built_set_memtab_info(struct sec_debug_memtab *mtab);
#else
static inline void secdbg_base_built_set_memtab_info(struct sec_debug_memtab *mtab) { }
#endif

#endif /* __SEC_DEBUG_INTERNAL_H__ */
