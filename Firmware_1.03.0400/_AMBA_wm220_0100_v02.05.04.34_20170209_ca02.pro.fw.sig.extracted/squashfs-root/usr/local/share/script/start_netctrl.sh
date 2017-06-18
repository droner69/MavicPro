#!/bin/sh

libambanetctrl_test svc netctrl &
libambanetctrl_test svc cmdhndlr &
libambanetctrl_test svc datareq &
