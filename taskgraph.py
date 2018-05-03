#!/usr/bin/env python3

# FileVersion=1

from taskw import TaskWarrior
from graphviz import Digraph
import re

dot = Digraph(comment='Taskwarrior')

ignore_tags = ['notes', 'dymo']
ignore_projects = ['notes']

w = TaskWarrior()
tasks = w.load_tasks()
for task in tasks['pending']:
    if 'recur' in task:
        continue
    found = 0
    if 'tags' in task:
        for tag in task['tags']:
            if tag in ignore_tags:
                found = 1
                break
    if 'project' in task:
        if task['project'] in ignore_projects:
            found = 1
    if found == 1:
        continue
    match = re.search( '(__)([^_]+)(__)', task["description"], flags = 0)
    if match:
        print ('A')
        description = match.group(2)
    else:
        print ('B')
        description = task['description']
    print (description)
    if 'priority' in task:
        if task['priority'] == "H":
            pcolor = 'red'
        if task['priority'] == "M":
            pcolor = 'green'
        if task['priority'] == "L":
            pcolor = 'black'
    else:
        pcolor = 'black'
    dot.node(task["uuid"], description, color = pcolor)
    if 'priority' in task and task['priority'] == "h":
        dot.node(task["uuid"], description, color='red')
    else:
        dot.node(task["uuid"], description)
    if 'depends' in task:
        for dependency in task['depends']:
            dot.edge(dependency, task["uuid"])

dot.render('/tmp/file', view=True)
