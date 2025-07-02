/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Samsung debugging features for Samsung's SoC's.
 *
 * Copyright (c) 2024 Samsung Electronics Co., Ltd.
 *      http://www.samsung.com
 */

#ifndef SEC_DEBUG_BUILT_H
#define SEC_DEBUG_BUILT_H

#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/types.h>
/*
 * Don't include additional headers. They can cause ABI violation problem
 * because this file is included many built-in drivers.
 */

struct task_struct;
struct irq_desc;

/*
 * SEC DEBUG AUTO COMMENT
 */
#if IS_ENABLED(CONFIG_SEC_DEBUG_AUTO_COMMENT)
extern void secdbg_comm_log_disable(int type);
extern void secdbg_comm_log_once(int type);
#define DEFINE_STATIC_PR_AUTO_NAME_ONCE(name, lvl)			\
	static atomic_t ___pr_auto_counter_##name = ATOMIC_INIT(-1);	\
	static const char *___pr_auto_level_##name = (lvl)

#define pr_auto_name_once(name)					\
({								\
	if (atomic_read(&___pr_auto_counter_##name) <= 0)	\
		atomic_inc(&___pr_auto_counter_##name);		\
})

#define pr_auto_name(name, fmt, ...)				\
({								\
	if (atomic_read(&___pr_auto_counter_##name) > 0)	\
		pr_emerg(fmt, ##__VA_ARGS__);			\
	else							\
		printk(KERN_AUTO "%s" pr_fmt(fmt),		\
				___pr_auto_level_##name, ##__VA_ARGS__);	\
})

#define pr_auto_name_disable(name)				\
({								\
	atomic_set(&___pr_auto_counter_##name, 1);		\
})

#define pr_auto_name_on(__pr_auto_cond, name, fmt, ...)	\
({								\
	if (__pr_auto_cond)					\
		pr_auto_name(name, fmt, ##__VA_ARGS__);	\
	else							\
		pr_emerg(fmt, ##__VA_ARGS__);			\
})

#define pr_auto_on(__pr_auto_cond, lvl, fmt, ...)	\
({							\
	if (__pr_auto_cond)				\
		pr_auto(lvl, fmt, ##__VA_ARGS__);	\
	else						\
		pr_emerg(fmt, ##__VA_ARGS__);		\
})
#else
#define DEFINE_STATIC_PR_AUTO_NAME_ONCE(name, lvl)
#define pr_auto_name_once(name)
#define pr_auto_name(name, fmt, ...)	pr_emerg(fmt, ##__VA_ARGS__)
#define pr_auto_name_disable(name)
#define pr_auto_name_on(__pr_auto_cond, name, fmt, ...)		pr_emerg(fmt, ##__VA_ARGS__)
#define pr_auto_on(__pr_auto_cond, lvl, fmt, ...)		pr_emerg(fmt, ##__VA_ARGS__)
#endif /* CONFIG_SEC_DEBUG_AUTO_COMMENT */

#if IS_ENABLED(CONFIG_SEC_DEBUG_PM_DEVICE_INFO)
extern void secdbg_base_built_set_shutdown_device(const char *fname, const char *dname);
extern void secdbg_base_built_set_suspend_device(const char *fname, const char *dname);
#else
#define secdbg_base_built_set_shutdown_device(a, b)		do { } while (0)
#define secdbg_base_built_set_suspend_device(a, b)		do { } while (0)
#endif /* CONFIG_SEC_DEBUG_PM_DEVICE_INFO */

#if IS_ENABLED(CONFIG_SEC_DEBUG_TASK_IN_STATE_INFO)
void secdbg_base_built_set_task_in_pm_suspend(struct task_struct *task);
void secdbg_base_built_set_task_in_sync_irq(struct task_struct *task, unsigned int irq, struct irq_desc *desc);
#else
#define secdbg_base_built_set_task_in_pm_suspend(a)		do { } while (0)
#define secdbg_base_built_set_task_in_sync_irq(a, b, c)		do { } while (0)
#endif /* CONFIG_SEC_DEBUG_TASK_IN_STATE_INFO */

#ifdef CONFIG_SEC_DEBUG_MEMTAB
struct secdbg_member_type {
	/* member string length is valid up to 64 bytes. The text after
	 * that will be ignored by bootloader
	 */
	const char *member;
	uint16_t size;
	uint16_t offset;
	uint16_t unused[2];
};

#define SECDBG_DEFINE_MEMBER_TYPE(key, st, mem)			\
	const struct secdbg_member_type sdbg_##key		\
		__section(".secdbg_mbtab." #key) = {		\
		.member = #key,					\
		.size = sizeof_field(struct st, mem),		\
		.offset = offsetof(struct st, mem),		\
	}
#else
#define SECDBG_DEFINE_MEMBER_TYPE(a, b, c)
#endif /* CONFIG_SEC_DEBUG_MEMTAB */

#endif /* SEC_DEBUG_BUILT_H */
