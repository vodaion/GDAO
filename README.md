[![Build Status](https://travis-ci.org/vadeara/GDAO.svg?branch=master)](https://travis-ci.org/vodaion/GDAO)
[![Version](https://img.shields.io/cocoapods/v/GDAO.svg?style=flat)](http://cocoapods.org/pods/GDAO)
[![License](https://img.shields.io/cocoapods/l/GDAO.svg?style=flat)](http://cocoapods.org/pods/GDAO)
[![Platform](https://img.shields.io/cocoapods/p/GDAO.svg?style=flat)](http://cocoapods.org/pods/GDAO)


# GDAO
The GDAO(G* Data Access Object) provides an abstract interface to CoreData and can be extend to support other persistence mechanism. Currently the focus is on CoreData DAO

By mapping application calls to the persistence layer, the DAO provides some specific data operations without exposing details of the database. 
This isolation supports the single responsibility principle. 
It separates what data access the application needs, in terms of domain-specific objects and data types (the public interface of the DAO), from how these needs can be satisfied with a specific DBMS, database schema, etc. (the implementation of the DAO). 

As a bonus it contains JSON to CoreData parser, this parser cand be extend to suport any persistence mechanism.
