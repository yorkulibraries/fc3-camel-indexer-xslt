<?xml version="1.0" encoding="UTF-8"?>
<!-- We need all lower level namespaces to be declared here for exclude-result-prefixes attributes
     to be effective -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:zs="http://www.loc.gov/zing/srw/"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:rel="info:fedora/fedora-system:def/relations-external#"
  xmlns:fedora-model="info:fedora/fedora-system:def/model#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
  xmlns:dwc="http://rs.tdwg.org/dwc/xsd/simpledarwincore/"
  xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
  xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/"
  xmlns:res="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:eaccpf="urn:isbn:1-931666-33-4"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:sparql="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:gsearch="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
  xmlns:dfxml="http://www.forensicswiki.org/wiki/Category:Digital_Forensics_XML"
  xmlns:islandora-exts="xalan://ca.upei.roblib.DataStreamForXSLT"
  exclude-result-prefixes="gsearch encoder"
  xmlns:encoder="xalan://java.net.URLEncoder"
  xmlns:java="http://xml.apache.org/xalan/java">

  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" encoding="UTF-8"/>

  <!-- gsearch magik @TODO: see if any of the explicit variables can be replaced by these -->
  <xsl:param name="REPOSITORYNAME" select="repositoryName"/>
  <xsl:param name="FEDORASOAP" select="repositoryName"/>
  <xsl:param name="FEDORAUSER" select="repositoryName"/>
  <xsl:param name="FEDORAPASS" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPATH" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPASS" select="repositoryName"/>

  <!-- These values are accessible in included xslts -->
  <xsl:variable name="PROT">http</xsl:variable>
  <xsl:variable name="HOST">localhost</xsl:variable>
  <xsl:variable name="PORT">8080</xsl:variable>
  <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
  <xsl:variable name="FEDORA" xmlns:java_string="xalan://java.lang.String" select="substring($FEDORASOAP, 1, java_string:lastIndexOf(java_string:new(string($FEDORASOAP)), '/'))"/>

  <!--
  This xslt stylesheet generates the IndexDocument consisting of IndexFields
    from a FOXML record. The IndexFields are:
      - from the root element = PID
      - from foxml:property   = type, state, contentModel, ...
      - from oai_dc:dc        = title, creator, ...
    The IndexDocument element gets a PID attribute, which is mandatory,
    while the PID IndexField is optional.
  -->

  <xsl:include href="islandora_transforms/DC_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/RELS-EXT_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/RELS-INT_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/FOXML_properties_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/datastream_id_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/slurp_all_ead_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/slurp_all_FITS_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/slurp_all_MODS_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/slurp_all_DFXML_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/EACCPF_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/TEI_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/text_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/XML_to_one_solr_field.xslt"/>
  <xsl:include href="islandora_transforms/XML_text_nodes_to_solr.xslt"/>
  <xsl:include href="islandora_transforms/MADS_to_solr.xslt"/>
  <!-- Used for indexing other objects.
  <xsl:include href="islandora_transforms/library/traverse-graph.xslt"/>
  -->

  <!-- Decide which objects to modify the index of -->
  <xsl:template match="/">
    <update>
      <!-- The following allows only active and data oriented FedoraObjects to be indexed -->
      <xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP' or @ID='DS-COMPOSITE-MODEL'])">
        <xsl:choose>
          <xsl:when test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
            <add>
              <xsl:apply-templates select="/foxml:digitalObject" mode="indexFedoraObject">
                <xsl:with-param name="PID" select="$PID"/>
              </xsl:apply-templates>
            </add>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="/foxml:digitalObject" mode="unindexFedoraObject"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </update>
  </xsl:template>

  <!-- Index an object -->
  <xsl:template match="/foxml:digitalObject" mode="indexFedoraObject">
    <xsl:param name="PID"/>
    <add>
    <doc>
      <!-- put the object pid into a field -->
      <field name="PID">
        <xsl:value-of select="$PID"/>
      </field>

      <!-- These templates are in the islandora_transforms -->
      <xsl:apply-templates select="foxml:objectProperties/foxml:property"/>
      <xsl:apply-templates select="/foxml:digitalObject" mode="index_object_datastreams"/>

      <!-- THIS IS SPARTA!!!
        These lines call a matching template on every datastream id so that you only have to edit included files
        handles inline and managed datastreams
        The datastream level element is used for matching,
        making it imperative to use the $content parameter for xpaths in templates
        if they are to support managed datstreams -->

      <!-- TODO: would like to get rid of the need for the content param -->
      <xsl:for-each select="foxml:datastream">
        <xsl:choose>
          <xsl:when test="@CONTROL_GROUP='X'">
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="foxml:datastreamVersion[last()]/foxml:xmlContent"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="@CONTROL_GROUP='M' and foxml:datastreamVersion[last()][@MIMETYPE='text/xml' or @MIMETYPE='application/xml' or @MIMETYPE='application/rdf+xml' or @MIMETYPE='text/html']">
            <!-- TODO: should do something about mime type filtering
              text/plain should use the getDatastreamText extension because document will only work for xml docs
              xml files should use the document function
              other mimetypes should not be being sent
              will this let us not use the content variable? -->
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="document(concat($PROT, '://', encoder:encode($FEDORAUSER), ':', encoder:encode($FEDORAPASS), '@', $HOST, ':', $PORT, '/fedora/objects/', $PID, '/datastreams/', @ID, '/content'))"/>
            </xsl:apply-templates>
          </xsl:when>
          <!-- non-xml managed datastreams...

               Really, should probably only
               handle the mimetypes supported by the "getDatastreamText" call:
               https://github.com/fcrepo/gsearch/blob/master/FedoraGenericSearch/src/java/dk/defxws/fedoragsearch/server/TransformerToText.java#L185-L200
          -->
            <xsl:when test="@CONTROL_GROUP='M' and foxml:datastreamVersion[last() and not(starts-with(@MIMETYPE, 'image') or starts-with(@MIMETYPE, 'audio') or starts-with(@MIMETYPE, 'video') or starts-with(@MIMETYPE, 'warc'))]">
            <!-- TODO: should do something about mime type filtering
              text/plain should use the getDatastreamText extension because document will only work for xml docs
              xml files should use the document function
              other mimetypes should not be being sent
              will this let us not use the content variable? -->
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="java:ca.discoverygarden.gsearch_extensions.XMLStringUtils.escapeForXML(normalize-space(gsearch:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)))"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>

      <!-- this is an example of using template modes to have multiple ways of indexing the same stream -->
      <!--
      <xsl:apply-templates select="foxml:datastream[@ID='EAC-CPF']/foxml:datastreamVersion[last()]/foxml:xmlContent//eaccpf:eac-cpf">
        <xsl:with-param name="pid" select="$PID"/>
      </xsl:apply-templates>

      <xsl:apply-templates mode="fjm" select="foxml:datastream[@ID='EAC-CPF']/foxml:datastreamVersion[last()]/foxml:xmlContent//eaccpf:eac-cpf">
        <xsl:with-param name="pid" select="$PID"/>
        <xsl:with-param name="suffix">_s</xsl:with-param>
      </xsl:apply-templates>
      -->
      
      <!-- Apache Tika 
      <xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M' or @CONTROL_GROUP='E' or @CONTROL_GROUP='R']">
        <xsl:value-of disable-output-escaping="no" select="exts:getDatastreamFromTika($PID, $REPOSITORYNAME, @ID, 'field', concat('ds.', @ID), concat('dsmd_', @ID, '.'), '', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
      </xsl:for-each> -->

      <!-- Creating an index field with all text from the foxml record and its datastream -->

      <field name="foxml.all.text">
        <xsl:for-each select="//text()">
          <xsl:value-of select="."/>
          <xsl:text>&#160;</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="//foxml:datastream[@CONTROL_GROUP='M' or @CONTROL_GROUP='E' or @CONTROL_GROUP='R']">
          <xsl:value-of select="gsearch:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
          <xsl:text>&#160;</xsl:text>
        </xsl:for-each>
      </field>
    </doc>
  </add>
  </xsl:template>

  <!-- This prevents text from just being printed to the doc without field elements JUST TRY COMMENTING IT OUT -->
  <xsl:template match="text()"/>
  <xsl:template match="text()" mode="indexFedoraObject"/>
  <xsl:template match="text()" mode="unindexFedoraObject"/>
  <xsl:template match="text()" mode="index_object_datastreams"/>
</xsl:stylesheet>
