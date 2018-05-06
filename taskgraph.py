#!/usr/bin/env python3

# FileVersion=5

from taskw import TaskWarrior
from graphviz import Digraph
import re

ignore_tags = ['notes', 'dymo']
ignore_projects = ['notes']
dot = Digraph(comment='Taskwarrior')
dot.attr(rankdir='LR', size='8,5', splines='line')
tasks_in = TaskWarrior().load_tasks()['pending']
tasks = []
priority_groups = []
group_counter = 0
group = []
group_priority = None
group_found = []


def check_has_banned_tag(task):
    if 'tags' in task:
        for tag in task['tags']:
            if tag in ignore_tags:
                return True
    return False


def check_has_banned_project(task):
    if 'project' in task:
        if task['project'] in ignore_projects:
            return True
    return False


def check_recurrent(task):
    if 'recur' in task:
        return True
    return False


def get_task_with_uuid(uuid):
    for task in tasks:
        if task['uuid'] == uuid:
            return task


def get_higher_priority(priority1, priority2):
    def map_priority(priority):
        if priority == 'L':
            return 0
        elif priority == 'M':
            return 1
        elif priority == 'H':
            return 2

    if map_priority(priority1) >= map_priority(priority2):
        return priority1
    else:
        return priority2


def get_task_priority(task):
    if 'priority' in task:
        return task['priority']
    else:
        return 'L'


def task_in_group(task_in):
    # Returns if a task is already on a priority group
    for group in priority_groups:
        for task in group['tasks']:
            if int(task['id']) == int(task_in['id']):
                return group['id']
    return 0


def add_task_group(task, length, priority='L'):
    global group_counter
    global group
    global group_priority
    global group_found
    global priority_groups

    if task_in_group(task) > 0:
        if length == 0:
            # First recursive call and task already in a group: exit
            pass
        else:
            # task already in a group, add group to be merged and return
            group_found.append(task_in_group(task))
    else:
        # task does not belong to another group
        priority = get_higher_priority(get_task_priority(task), priority)

        if length == 0:
            group = []
            group_priority = priority
            group_found = []
        group.append(task)
        if 'depends' in task:
            for uuid in task['depends']:
                add_task_group(get_task_with_uuid(uuid), priority=priority,
                               length=length + 1)

        group_counter += 1  # Get new group id
        if length == 0 and not group_found:
            priority_groups.append({'id': group_counter, 'tasks': group,
                                    'priority': priority})
        elif length == 0 and group_found:
            # Merge group_found's and temporary 'group' into a new group
            for g in priority_groups:
                if g['id'] in group_found:
                    priority = get_higher_priority(priority, g['priority'])
                    group.extend(g['tasks'])
            for g in priority_groups[:]:
                if g['id'] in group_found:
                    priority_groups.remove(g)
            priority_groups.append({'id': group_counter, 'tasks': group,
                                    'priority': priority})


# Discard unwanted tasks:
for task in tasks_in:
    if not (check_recurrent(task) or check_has_banned_tag(task) or
            check_has_banned_project(task)):
        tasks.append(task)

# Get higher priority (root parent) for every task, including its dependencies
# and only for tasks without reverse dependencies:
for task in tasks:
    add_task_group(task, length=0)

for cluster in ['Low', 'Medium', 'High']:
    priority_found = False
    for group in priority_groups:
        if group['priority'] == cluster[0:1]:
            priority_found = True
            break
    if not priority_found:
        continue
    with dot.subgraph(name='cluster_'+cluster) as c:
        c.attr(rankdir='TB')
        c.attr(style='filled')
        c.attr(color='lightgrey')
        c.node_attr.update(style='filled', color='white')
        c.attr(label=cluster)
        for group in priority_groups:
            if not group['priority'] == cluster[0:1]:
                continue

            for task in group['tasks']:
                if 'priority' in task and task['priority'] == "H":
                    color = 'red'
                elif 'priority' in task and task['priority'] == "M":
                    color = 'green'
                else:
                    color = 'white'

                match = re.search( '(__)([^_]+)(__)', task["description"], flags = 0)
                if match:
                    description = match.group(2)
                else:
                    description = task['description']

                c.node(task["uuid"], description + "(" + str(task['id']) + ")", color = color)
                if 'depends' in task:
                    for dependency in task['depends']:
                        c.edges([(task['uuid'], dependency)])


dot.view()
# dot.render('/tmp/file', view=True)
