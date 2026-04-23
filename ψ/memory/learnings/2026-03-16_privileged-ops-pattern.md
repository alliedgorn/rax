# Privileged Operations Need a Pattern

**Date**: 2026-03-16
**Source**: rrr: rax
**Concepts**: security, infrastructure, sudo, operations

## Pattern

Running sudo commands in AI sessions requires the human to share their password in plaintext. This is a security risk. Need a better pattern for privileged infrastructure operations.

## Options to explore

- Pre-authorized sudo for specific commands (sudoers NOPASSWD for safe ops like swapfile creation)
- Helper scripts that Gorn runs manually for privileged steps
- A "run this in your terminal" handoff for anything requiring root

## Application

- Before any sudo operation, plan the full command sequence and present it to Gorn
- Never store or cache passwords
- Flag any password exposure immediately
