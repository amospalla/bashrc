#!/usr/bin/env python3

# FileVersion=3

from taskw import TaskWarrior
from graphviz import Digraph
import re

ignore_tags = ['notes', 'dymo']
ignore_projects = ['notes']

dot = Digraph(comment='Taskwarrior')
tasks_in = TaskWarrior().load_tasks()['pending']
tasks = []
root_priorities = {}
task_has_parents = {}


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


def get_task_priority_recursive(task):
    if 'priority' in task:
        highest_priority = task['priority']
    else:
        highest_priority = 'L'

    if 'depends' in task:
        for uuid in task['depends']:
            task_has_parents[uuid] = True
            dep_priority = get_task_priority_recursive(get_task_with_uuid(uuid))
            highest_priority = get_higher_priority(highest_priority, dep_priority)
    return highest_priority


# Discard unwanted tasks:
for task in tasks_in:
    if not (check_recurrent(task) or check_has_banned_tag(task) or check_has_banned_project(task)):
        tasks.append(task)

# Set parent a root priority:
for task in tasks:
    root_priorities[task['uuid']] = 'Low'
    task_has_parents[task['uuid']] = False

# Get higher priority (root parent) for every task, including its dependencies
# and only for tasks without reverse dependencies:
for task in tasks:
    root_priorities[task['uuid']]=(get_task_priority_recursive(task))

dot.node('H', 'High', color='red')
dot.node('M', 'Medium', color='green')
dot.node('L', 'Low', color='black')

for task in tasks:
    if 'priority' in task:
        if task['priority'] == "H":
            pcolor = 'red'
        if task['priority'] == "M":
            pcolor = 'green'
        if task['priority'] == "L":
            pcolor = 'black'
    else:
        pcolor = 'black'

    match = re.search( '(__)([^_]+)(__)', task["description"], flags = 0)
    if match:
        description = match.group(2)
    else:
        description = task['description']

    dot.node(task["uuid"], description, color = pcolor)
    if 'priority' in task and task['priority'] == "H":
        dot.node(task["uuid"], description, color='red')
    elif 'priority' in task and task['priority'] == "M":
        dot.node(task["uuid"], description, color='green')
    else:
        dot.node(task["uuid"], description)

    if 'depends' in task:
        for dependency in task['depends']:
            dot.edge(task["uuid"], dependency)
    if not task_has_parents[task['uuid']]:
        dot.edge(root_priorities[task['uuid']], task["uuid"])

dot.render('/tmp/file', view=True)
