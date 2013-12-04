<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
    xmlns:m="http://www.example.org/stock">
    <xsl:template match="/">
        <xsl:apply-templates select="soap:Envelope/soap:Body/*"/>
    </xsl:template>
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
