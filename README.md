# fc3 camel indexer xslt

## Summary

This repo holds the XSLTs for [fc3-camel-indexer](https://github.com/uml-digitalinitiatives/fc3-camel-indexer), for [York University Digital Library](http://digital.library.yorku.ca/).

## Usage

1. Clone, build [fc3-camel-indexer](https://github.com/uml-digitalinitiatives/fc3-camel-indexer)
2. Update `JAVA_OPTS` in `/etc/default/tomcat7` to include:
  * `-Dfedora3.indexer.xslt=/home/nruest/git/fc3-camel-indexer-xslt/foxmlToSolr.xslt`
  * `-Dfedora3.indexer.fedoraPass=FEDORAPASS`
  * `-Dfedora3.indexer.concurrent=40`
3. Stop Tomcat
4. Deploy `fc3-camel-indexer.war`
5. Start Tomcat

## Thank you

* [Jared Whiklo](https://github.com/whikloj)
* [Aaron Coburn](https://github.com/acoburn)
