<?xml version="1.0" encoding="UTF-8"?>
<?altova_samplexml file:///D:/Schematron/XNAT/protocol.report.xml?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:val="http://nrg.wustl.edu/val" xmlns:xnat="http://nrg.wustl.edu/xnat" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns:nrgxsl="http://nrg.wustl.edu/validate" xmlns:prov="http://www.nbirn.net/prov" xmlns:ext="org.nrg.validate.utils.ProvenanceUtils">
<xsl:output method="text" indent="yes" />
<!-- Pass the following parameters on the commandline. These are used for provenance-->

<xsl:param name="session_label"/>
<xsl:param name="series_description"/>

 
<xsl:param name="now-date"><xsl:value-of select="ext:GetDate()"/></xsl:param>
<xsl:param name="now-time"><xsl:value-of select="ext:GetTime()"/></xsl:param>
<xsl:template match="/">
<xsl:message>Generating Validation Document</xsl:message>
Date: <xsl:value-of select="$now-date"/>
Session: <xsl:value-of select="$session_label"/>
Session ID: <xsl:value-of select="/svrl:schematron-output/svrl:successful-report[@id='expt_id']/svrl:text"/>
Project: <xsl:value-of select="/svrl:schematron-output/svrl:successful-report[@id='expt_project']/svrl:text"/>

		 <xsl:for-each select="//nrgxsl:scans">
			<xsl:call-template name="process-scan">
				<xsl:with-param name="scan-id" select="normalize-space(.)" />
			</xsl:call-template>
	 	  </xsl:for-each>
	<xsl:message>DONE</xsl:message>
</xsl:template>

<xsl:template name="process-scan">
	<xsl:param name="scan-id"/>

		<xsl:choose>
			      <xsl:when test="count(//nrgxsl:scan[@id=$scan-id])=0">
					Scan: <xsl:value-of select="$scan-id"/> (<xsl:value-of select="$series_description"/>) Outlier Check: No checks defined
			      </xsl:when>	
			      <xsl:otherwise>
				      <xsl:choose>
				      <xsl:when test="count(/svrl:schematron-output/svrl:failed-assert/svrl:text/nrgxsl:scan[@id=$scan-id])>0">
						Scan: <xsl:value-of select="$scan-id"/> (<xsl:value-of select="$series_description"/>) Outlier Check: fail
				       </xsl:when>
				       <xsl:otherwise>
						Scan: <xsl:value-of select="$scan-id"/> (<xsl:value-of select="$series_description"/>) Outlier Check: pass
				       </xsl:otherwise>
				       </xsl:choose>
			       </xsl:otherwise>
		</xsl:choose>	       

		<xsl:for-each select="//nrgxsl:scan[@id=$scan-id]">

			<xsl:choose>
				<xsl:when test="name(../..)='svrl:failed-assert'">
<xsl:value-of select="normalize-space(@cause-id)"/>	fail (<xsl:value-of select="normalize-space(.)"/>)
				</xsl:when>
				<xsl:otherwise>
<xsl:value-of select="normalize-space(@cause-id)"/>	pass (<xsl:value-of select="normalize-space(.)"/>)
				</xsl:otherwise>
			</xsl:choose>
			

			</xsl:for-each> 

	
</xsl:template>

</xsl:stylesheet>
