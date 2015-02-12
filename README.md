Gekko [![Build Status](https://secure.travis-ci.org/Paymium/gekko.png?branch=master)](http://travis-ci.org/Paymium/gekko) [![Coverage Status](https://img.shields.io/coveralls/Paymium/gekko.svg)](https://coveralls.io/r/Paymium/gekko?branch=master) [![Gem Version](https://badge.fury.io/rb/gekko.svg)](http://badge.fury.io/rb/gekko)
=

## What Gekko is
Gekko is intended to become a high-performance in-memory trade order matching engine.

## What Gekko is not
Gekko is not intended to maintain an accounting database, it just matches trade orders associated to accounts, and returns the necessary data for an accounting system to record the trades (usually against some sort of RDBMS).

## Left to do
The following items are left to do and will need to be implemented before gekko is considered production-ready.

 - Persistence and failure recovery
 - Add and enforce minimum and maximum order sizes
 - Correctly handle order expiration

