#!/usr/bin/env python
# cSpell:includeRegExp /".*",/
# cSpell:includeRegExp /\(f?".*"/
#
# Template doc:
# https://adamj.eu/tech/2021/10/09/a-python-script-template-with-and-without-type-hints-and-async/
#
# Author      :
# Date        :
# Description :
# License     : Gnu GPL
# Created on  : <use `:read !date -I` then `J` > 2022-10-07

from __future__ import annotations

import argparse
from collections.abc import Sequence


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="A template doing nothing")
    # Add arguments here
    # parser.add_argument("-d", action="store_true", dest="debug",
    #    help='Debug mode', required=False)
    args = parser.parse_args(argv)
    print(args)

    # Implement behavior here

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
