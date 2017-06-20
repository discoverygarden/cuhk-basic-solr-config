<?xml version="1.0" encoding="UTF-8"?>
<!-- Basic MODS -->
<xsl:stylesheet version="1.0"
  xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"
     exclude-result-prefixes="mods java">
  <!-- <xsl:include href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <xsl:include href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>
  <!-- <xsl:include href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/> -->
  <xsl:include href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/>
  <!-- HashSet to track single-valued fields. -->
  <xsl:variable name="single_valued_hashset" select="java:java.util.HashSet.new()"/>
    <xsl:variable name="vAllowedSymbols" select="'&#x5b;&#x5d;&#x3c;&#x3e;&#x28;&#x29;&#x2f;&#x2c;&#x2d;'"/>
  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS">
    <xsl:param name="content"/>
    <xsl:param name="prefix"></xsl:param>
    <xsl:param name="suffix">ms</xsl:param>

    <!-- Clearing hash in case the template is ran more than once. -->
    <xsl:variable name="return_from_clear" select="java:clear($single_valued_hashset)"/>
    
    <xsl:apply-templates mode="slurping_MODS" select="$content//mods:mods[1]">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="../../@PID"/>
      <xsl:with-param name="datastream" select="../@ID"/>
    </xsl:apply-templates>
    
    <xsl:apply-templates mode="cuhk_slurping_MODS" select="$content//mods:mods[1]">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="../../@PID"/>
      <xsl:with-param name="datastream" select="../@ID"/>
    </xsl:apply-templates>
    <xsl:apply-templates mode="cuhk_slurping_subject_MODS" select="$content//mods:mods[1]/mods:subject"></xsl:apply-templates> 
    <xsl:apply-templates mode="cuhk_slurping_titleInfo_MODS" select="$content//mods:mods[1]/mods:titleInfo[@type=''] | $content//mods:mods[1]/mods:titleInfo[not(@type)]"></xsl:apply-templates>   
    <xsl:apply-templates mode="cuhk_slurping_originInfo_MODS" select="$content//mods:mods[1]/mods:originInfo"></xsl:apply-templates>   
    <xsl:apply-templates mode="cuhk_slurping_originInfo_dateCreated_MODS" select="$content//mods:mods[1]/mods:originInfo[1]"></xsl:apply-templates>   
    <xsl:apply-templates mode="cuhk_slurping_relatedItem_MODS" select="$content//mods:mods[1]/mods:relatedItem[@type='host']/mods:titleInfo"></xsl:apply-templates>
    <xsl:apply-templates mode="cuhk_slurping_name_MODS" select="$content//mods:mods[1]/mods:name"></xsl:apply-templates>
    
  </xsl:template>
  <!-- Merge all subject sub tab into one field. -->
    <xsl:template match="*" mode="cuhk_slurping_subject_MODS">
        <!--<xsl:if test="mods:topic or mods:geographic">-->
        <xsl:variable name="subjectItem">
            <xsl:for-each select="*[local-name()!='cartographics' and local-name()!='geographicCode' and local-name()!='hierarchicalGeographic']">
                <xsl:if test="normalize-space(.) != ''">
                    <xsl:if test="position() > 1">
                        <xsl:if test="not(normalize-space(.)='')"> -- </xsl:if>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <!--</xsl:if>-->
        <xsl:if test="not(normalize-space($subjectItem)= '')">
            <field name="mods_subject_topic_merge_ms">
                <xsl:value-of select="$subjectItem"/>
                <xsl:if test="not(substring($subjectItem, (string-length($subjectItem) - string-length('.')) + 1)='.')">
                    <xsl:value-of select="'.'"/>
                </xsl:if>
            </field>
        </xsl:if>
   </xsl:template>
    <!-- Merge all titleInfo fields into one field. -->
    <xsl:template match="*" mode="cuhk_slurping_titleInfo_MODS">
        <xsl:variable name="titleItem">
            <xsl:for-each select="*[local-name()='nonSort' or local-name()='title' or local-name()='subTitle']">
                <xsl:if test="normalize-space(.) != ''">
                    <xsl:if test="position() > 1 and local-name() != 'subTitle'">
                        <xsl:if test="not(normalize-space(.)='')"><xsl:value-of select="' '"/></xsl:if>
                    </xsl:if>
                    <xsl:if test="local-name() = 'subTitle'">
                        <xsl:if test="not(normalize-space(.)='')"> : </xsl:if>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="normalize-space($titleItem) != ''">
            <field name="mods_titleInfo_merge_ms">
                <xsl:value-of select="$titleItem"/>
            </field>
        </xsl:if>
   </xsl:template>
   <!-- Merge below two conditions into new field
    * 1. place/placeTerm (with attribute type which value equal to 'text') under originInfo
    * 2. publisher under originInfo
    * 3. dateIssued (with attribute qualifier)
    -->
    <xsl:template match="*" mode="cuhk_slurping_originInfo_MODS">
        <xsl:if test="mods:place/mods:placeTerm[@type='text'] or mods:publisher">
            <xsl:variable name="titleItem">
                <xsl:for-each select="mods:place/mods:placeTerm[@type='text']">
                    <xsl:if test="position() > 1">
                        <xsl:if test="not(normalize-space(.)='')"><xsl:value-of select="' '"/></xsl:if>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:for-each>
                <xsl:for-each select="mods:publisher">
                    <xsl:if test="normalize-space(.) != ''">
                        <xsl:if test="not(normalize-space(.)='')"><xsl:value-of select="' '"/></xsl:if>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="mods:dateIssued[@qualifier]">
                    <xsl:if test="normalize-space(.) != ''">
                        <xsl:if test="not(normalize-space(.)='')"><xsl:value-of select="' '"/></xsl:if>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:if test="normalize-space($titleItem) != ''">
                <field name="mods_originInfo_place_publisher_merge_ms">
                    <xsl:value-of select="$titleItem"/>
                </field>
            </xsl:if>
        </xsl:if>
        <!-- 
        * Try to greb the created date from originalInfo tab and store in a new field
        --> 
        <xsl:if test="mods:dateIssued[count(@*)=0] or mods:dateCreated[count(@*)=0]">
            <xsl:variable name="dateCreated">
                <xsl:for-each select="mods:dateIssued[count(@*)=0]">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:for-each>
                <xsl:for-each select="mods:dateCreated[count(@*)=0]">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:if test="normalize-space($dateCreated) != ''">
                
                <field name="mods_created_date_year_ms">
                    <xsl:value-of select="translate($dateCreated,$vAllowedSymbols,'')"/>
                </field>
                
            </xsl:if>
        </xsl:if>
   </xsl:template>
   <!-- 
    * Try to greb the created date from originalInfo tab and store in the sortable field
    * Single Value Required
    --> 
   <xsl:template match="*" mode="cuhk_slurping_originInfo_dateCreated_MODS">
       <xsl:if test="mods:dateIssued[count(@*)=0] or mods:dateCreated[count(@*)=0]">
            <xsl:variable name="dateCreatedSingle">
                <xsl:value-of select="normalize-space(mods:dateIssued[count(@*)=0])"/>
                <xsl:value-of select="normalize-space(mods:dateCreated[count(@*)=0])"/>
            </xsl:variable>
            <xsl:if test="normalize-space($dateCreatedSingle) != ''">
                <field name="mods_created_date_year_ss">
                    <xsl:value-of select="translate($dateCreatedSingle,$vAllowedSymbols,'')"/>
                </field>
            </xsl:if>
        </xsl:if>
   </xsl:template>
   <!-- Below three sub items under relatedItem (with attribute type which value equal to 'host')
    * 1. nonSort
    * 2. title
    * 3. subTitle
    --> 
    <xsl:template match="*" mode="cuhk_slurping_relatedItem_MODS">
        <xsl:if test="mods:nonSort or mods:title or mods:subTitle">
            <xsl:variable name="relatedItem_title">
                <xsl:for-each select="*[local-name()='nonSort' or local-name()='title' or local-name()='subTitle']">
                    <xsl:if test="normalize-space(.) != ''">
                        <xsl:if test="position() > 1 and local-name() != 'subTitle'">
                            <xsl:if test="not(normalize-space(.)='')"><xsl:value-of select="' '"/></xsl:if>
                        </xsl:if>
                        <xsl:if test="local-name() = 'subTitle'">
                            <xsl:if test="not(normalize-space(.)='')"> : </xsl:if>
                        </xsl:if>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:if test="normalize-space($relatedItem_title) != ''">
                <field name="mods_relatedItem_host_titleInfo_merge_ms">
                    <xsl:value-of select="$relatedItem_title"/>
                </field>
            </xsl:if>
        </xsl:if>
   </xsl:template>
   <!-- Custom mapping for merging 
    - name[personal][namePart] and name[role][roleTerm]
    - name[corporate][namePart] and name[role][roleTerm]
  -->
   <xsl:template match="*" mode="cuhk_slurping_name_MODS">
        <xsl:variable name="nameRoleTerm">
            <xsl:for-each select="mods:role/mods:roleTerm">
                 <xsl:value-of select="concat('(',translate(normalize-space(.),'.',''),')')"/>
             </xsl:for-each>
        </xsl:variable>
        <xsl:for-each select="mods:namePart">
            <field name="mods_name_role_info_merge_ms">
                <xsl:if test="normalize-space(.) != ''">
                    <xsl:value-of select="translate(normalize-space(.),'.','')"/>
                    <xsl:if test="normalize-space($nameRoleTerm) != ''">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="normalize-space($nameRoleTerm)"/>
                    </xsl:if>
                </xsl:if>
            </field>
        </xsl:for-each>
   </xsl:template>
  <!-- Handle dates. -->
  <xsl:template match="mods:*[(@type='date') or (contains(translate(local-name(), 'D', 'd'), 'date'))][normalize-space(text())]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>

    <xsl:variable name="rawTextValue" select="normalize-space(text())"/>

    <xsl:variable name="textValue">
      <xsl:call-template name="get_ISO8601_date">
        <xsl:with-param name="date" select="$rawTextValue"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Use attributes in field name. -->
    <xsl:variable name="this_prefix">
      <xsl:value-of select="$prefix"/>
      <xsl:for-each select="@*">
        <xsl:sort select="concat(local-name(), namespace-uri(self::node()))"/>
        <xsl:value-of select="local-name()"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>_</xsl:text>
      </xsl:for-each>
    </xsl:variable>

    <!-- Prevent multiple generating multiple instances of single-valued fields
         by tracking things in a HashSet -->
    <xsl:variable name="field_name" select="normalize-space(concat($this_prefix, local-name()))"/>
    <!-- The method java.util.HashSet.add will return false when the value is
         already in the set. -->
    <xsl:if test="java:add($single_valued_hashset, $field_name)">
      <xsl:if test="not(normalize-space($textValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_dt')"/>
          </xsl:attribute>
          <xsl:value-of select="$textValue"/>
        </field>
      </xsl:if>
      <xsl:if test="not(normalize-space($rawTextValue)='')">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($field_name, '_s')"/>
          </xsl:attribute>
          <xsl:value-of select="$rawTextValue"/>
        </field>
      </xsl:if>
    </xsl:if>

    <xsl:if test="not(normalize-space($textValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_mdt')"/>
        </xsl:attribute>
        <xsl:value-of select="$textValue"/>
      </field>
    </xsl:if>
    <xsl:if test="not(normalize-space($rawTextValue)='')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_ms')"/>
        </xsl:attribute>
        <xsl:value-of select="$rawTextValue"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!-- Avoid using text alone. -->
  <xsl:template match="text()" mode="slurping_MODS"/>
  <!-- Tony  update here-->
  
  <!-- Build up the list prefix with the element context. -->
  <xsl:template match="*" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="this_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(@type, '_')"/>
      </xsl:if>
    </xsl:variable>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$this_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Build up the list prefix with the element context. -->
  <xsl:template match="*" mode="cuhk_slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    
    <xsl:variable name="this_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
    </xsl:variable>
    
    <xsl:apply-templates mode="cuhk_slurping_MODS">
      <xsl:with-param name="prefix" select="$this_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- Custom mapping for CUHK name type corporate. -->
  <!--<xsl:template match="mods:name[@type='corporate']" mode="cuhk_slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="value">
      <xsl:for-each select="mods:namePart[not(@*)]">
        <xsl:if test="not(normalize-space(.)='')">
          <xsl:value-of select="concat(normalize-space(.), ' ')"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable> 
    
  <xsl:if test="not(normalize-space($value)='')">
      <xsl:variable name="prefix_fork" select="concat($prefix, 'name_corporate_namePart_merge_')"/>
      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="$prefix_fork"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="normalize-space($value)"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node/mods:namePart"/>
        <xsl:with-param name="node" select="$node/mods:namePart[not(@*)][1]"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>-->
   
  <!-- Custom mapping for CUHK namePart type personal and corporate -->
  <xsl:template match="mods:name[@type='personal']|mods:name[@type='corporate']" mode="cuhk_slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="nameAttribute" select="normalize-space(local-name())"/>
    <xsl:variable name="typeName">
        <xsl:value-of select="normalize-space(@type)" />
    </xsl:variable>
    <xsl:variable name="tempNamePartFamily">
        <xsl:for-each select="mods:namePart[@type='family']">
            <xsl:if test="normalize-space(.) != ''">
                <xsl:if test="position() > 1">
                    <xsl:value-of select="' '"/>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="tempNamePartGiven">
        <xsl:for-each select="mods:namePart[@type='given']">
            <xsl:if test="not(normalize-space(.)='')">
              <xsl:if test="position() > 1">
                    <xsl:value-of select="' '"/>
                </xsl:if>
              <xsl:value-of select="normalize-space(.)"/>
           </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="tempNamePart">
        <xsl:for-each select="mods:namePart[count(@*)=0]">
            <xsl:if test="not(normalize-space(.)='')">
              <xsl:if test="position() > 1">
                    <xsl:value-of select="' '"/>
                </xsl:if>
              <xsl:value-of select="normalize-space(.)"/>
           </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="tempNamePartTermsOfAddress">
        <xsl:for-each select="mods:namePart[@type='termsOfAddress']">
            <xsl:if test="not(normalize-space(.)='')">
                <xsl:if test="position() > 1">
                    <xsl:value-of select="' '"/>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="tempNamePartDate">
        <xsl:for-each select="mods:namePart[@type='date']">
            <xsl:if test="not(normalize-space(.)='')">
                <xsl:if test="position() > 1">
                    <xsl:value-of select="' '"/>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
                
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="tempValue">
        <xsl:if test="not(normalize-space($tempNamePartFamily)='')">
            <xsl:value-of select="$tempNamePartFamily"/>
        </xsl:if>
        <xsl:if test="normalize-space($tempNamePartGiven)!=''">
            <xsl:if test="not(normalize-space($tempNamePartFamily)='')">
                <xsl:value-of select="', '"/>
            </xsl:if>
            <xsl:value-of select="$tempNamePartGiven"/>
        </xsl:if>
        <xsl:if test="not(normalize-space($tempNamePart)='')">
            <xsl:if test="not(normalize-space($tempNamePartFamily)='') or not(normalize-space($tempNamePartGiven)='')">
                <xsl:value-of select="', '"/>
            </xsl:if>
            <xsl:value-of select="$tempNamePart"/>
        </xsl:if>
        <xsl:if test="not(normalize-space($tempNamePartTermsOfAddress)='')">
            <xsl:if test="not(normalize-space($tempNamePartFamily)='') or not(normalize-space($tempNamePartGiven)='') or not(normalize-space($tempNamePart)='')">
                <xsl:value-of select="', '"/>
            </xsl:if>
            <xsl:value-of select="$tempNamePartTermsOfAddress"/>
        </xsl:if>
        <xsl:if test="not(normalize-space($tempNamePartDate)='')">
            <xsl:if test="not(normalize-space($tempNamePartFamily)='') or not(normalize-space($tempNamePartGiven)='') or not(normalize-space($tempNamePart)='') or not(normalize-space($tempNamePartTermsOfAddress)='')">
                <xsl:value-of select="', '"/>
            </xsl:if>
            <xsl:value-of select="$tempNamePartDate"/>
        </xsl:if>
    </xsl:variable>
    
    
    <xsl:variable name="prefix_fork">
        <xsl:value-of select="$prefix"/>
        <!--<xsl:choose>-->
            <xsl:if test="$typeName='corporate'">
                <xsl:value-of select="'name_corporate_namePart_merge_'"/>
            </xsl:if>
            <xsl:if test="$typeName='personal'">
                <xsl:value-of select="'name_personal_namePart_merge_'"/>
            </xsl:if>
        <!--</xsl:choose>-->
    </xsl:variable>
    <!--<xsl:variable name="prefix_fork" select="concat($prefix, 'name_personal_namePart_merge_')"/>-->
    <xsl:if test="not(normalize-space($tempValue)='')">
        <xsl:variable name="value">
            <xsl:value-of select="$tempValue"/>
            <xsl:if test="not(substring($tempValue, (string-length($tempValue) - string-length('.')) + 1)='.')">
                <xsl:value-of select="'.'"/>
            </xsl:if>
        </xsl:variable>
        <xsl:call-template name="mods_language_fork">
          <xsl:with-param name="prefix" select="$prefix_fork"/>
          <xsl:with-param name="suffix" select="$suffix"/>
          <xsl:with-param name="value" select="$value"/>
          <xsl:with-param name="pid" select="$pid"/>
          <xsl:with-param name="datastream" select="$datastream"/>
          <xsl:with-param name="node" select="$node/mods:namePart"/>
        </xsl:call-template>
     </xsl:if>
     
  </xsl:template>
   <xsl:template match="mods:name[@type='corporate']" mode="cuhk_slurping_MODS">
       <xsl:param name="prefix"/>
        <xsl:param name="suffix"/>
        <xsl:param name="value"/>
        <xsl:param name="pid">not provided</xsl:param>
        <xsl:param name="datastream">not provided</xsl:param>
        <xsl:param name="node" select="current()"/>
        <xsl:variable name="nameAttribute" select="normalize-space(local-name())"/>
        
        <xsl:variable name="tempDepartment">
            <xsl:for-each select="mods:namePart[count(@*)=0]">
                <xsl:if test="not(normalize-space(.)='')">
                  <xsl:if test="position() = last()">
                        <xsl:value-of select="normalize-space(.)"/>
                  </xsl:if>
               </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="prefix_fork">
            <xsl:value-of select="$prefix"/>
            <xsl:value-of select="'name_corporate_department_'"/>
        </xsl:variable>
        <xsl:if test="not(normalize-space($tempDepartment)='')">
            <xsl:variable name="value">
                <xsl:value-of select="$tempDepartment"/>
            </xsl:variable>
            <xsl:call-template name="mods_language_fork">
              <xsl:with-param name="prefix" select="$prefix_fork"/>
              <xsl:with-param name="suffix" select="$suffix"/>
              <xsl:with-param name="value" select="$value"/>
              <xsl:with-param name="pid" select="$pid"/>
              <xsl:with-param name="datastream" select="$datastream"/>
              <xsl:with-param name="node" select="$node/mods:namePart"/>
            </xsl:call-template>
         </xsl:if>
    </xsl:template>
    <!--
    * 1.Get value from note field where type equal to thesis
    * 2.Get the degree in string
    -->
    <xsl:template match="mods:note[@type='thesis']" mode="cuhk_slurping_MODS">
       <xsl:param name="prefix"/>
        <xsl:param name="suffix"/>
        <xsl:param name="value"/>
        <xsl:param name="pid">not provided</xsl:param>
        <xsl:param name="datastream">not provided</xsl:param>
        <xsl:param name="node" select="current()"/>
        <xsl:variable name="nameAttribute" select="normalize-space(local-name())"/>
        <xsl:variable name="tempValue">
            <xsl:for-each select=".">
                <xsl:if test="not(normalize-space(.)='')">
                    <xsl:value-of select="substring-after(normalize-space(.),'(')"/>
               </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="tempValue1">
            <xsl:if test="not(normalize-space($tempValue)='')">
                <xsl:value-of select="substring-before(normalize-space($tempValue),')')"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="tempDegree">
            
            <xsl:if test="not(normalize-space($tempValue1)='')">
                <xsl:value-of select="normalize-space($tempValue1)"/>
           </xsl:if>
            
        </xsl:variable>
        <xsl:variable name="prefix_fork">
            <xsl:value-of select="$prefix"/>
            <xsl:value-of select="'name_degree_'"/>
        </xsl:variable>
        <xsl:if test="not(normalize-space($tempDegree)='')">
            <xsl:variable name="value">
                <xsl:value-of select="$tempDegree"/>
            </xsl:variable>
            <xsl:call-template name="mods_language_fork">
              <xsl:with-param name="prefix" select="$prefix_fork"/>
              <xsl:with-param name="suffix" select="$suffix"/>
              <xsl:with-param name="value" select="$value"/>
              <xsl:with-param name="pid" select="$pid"/>
              <xsl:with-param name="datastream" select="$datastream"/>
              <xsl:with-param name="node" select="$node"/>
            </xsl:call-template>
         </xsl:if>
    </xsl:template>
  <!--<xsl:template match="mods:name[@type='personal'][mods:namePart[@type='termsOfAddress']]" mode="cuhk_slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:if test="not(normalize-space(mods:namePart[not(@*)][1]) ='') and not(normalize-space(mods:namePart[@type='termsOfAddress'][1])='')">
      <xsl:variable name="value" select="concat(normalize-space(mods:namePart[not(@*)][1]), ', ', normalize-space(mods:namePart[@type='termsOfAddress'][1]))"/>
      <xsl:variable name="prefix_fork" select="concat($prefix, 'name_personal_namePart_merge_')"/>
      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="$prefix_fork"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="mods:namePart[@type='termsOfAddress'][1]"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>-->
  
  <!-- Intercept names with role terms, so we can create copies of the fields
    including the role term in the name of generated fields. (Hurray, additional
    specificity!) -->
  <xsl:template match="mods:name[mods:role/mods:roleTerm]" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:variable name="base_prefix">
      <xsl:value-of select="concat($prefix, local-name(), '_')"/>
      <xsl:if test="@type">
        <xsl:value-of select="concat(@type, '_')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:for-each select="mods:role/mods:roleTerm">
      <xsl:variable name="this_prefix" select="concat($base_prefix, translate(normalize-space(.), $uppercase, $lowercase), '_')"/>

      <xsl:call-template name="mods_language_fork">
        <xsl:with-param name="prefix" select="$this_prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="normalize-space(text())"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="../.."/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:call-template name="mods_language_fork">
      <xsl:with-param name="prefix" select="$base_prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="normalize-space(text())"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Custom mapping for titleInfo/partNumber so we can sort numerically. Of
       possible importance to note is that the partNumber field should only
       contain one contiguous integer; if the field contains something such as
       "Vol. 1, iss. 12", this will interpret that field as "112", which is not
       likely desirable. -->
  <xsl:template match="mods:titleInfo/mods:partNumber" mode="slurping_MODS">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="field_name" select="concat($prefix, 'partNumber_sortable_fork_i')"/>
    <xsl:if test="not(normalize-space($node/../mods:partNumber[not(@*)][1]) ='') and not(normalize-space(.)='') and java:add($single_valued_hashset, $field_name)">
      <xsl:variable name="value" select="normalize-space($node/../mods:partNumber[not(@*)][1])"/>
      <xsl:variable name="number_value" select="translate($value, translate($value, '0123456789', ''), '')"/>
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="$field_name"/>
        </xsl:attribute>
        <xsl:value-of select="$number_value"/>
      </field>
    </xsl:if>
  </xsl:template>


  <!-- Fields are duplicated for authority because searches across authorities are common. -->
  <xsl:template name="mods_authority_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="general_mods_field">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@authority">
      <xsl:call-template name="general_mods_field">
        <xsl:with-param name="prefix" select="concat($prefix, 'authority_', translate(@authority, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

   <!-- Want to include language in field names. -->
  <xsl:template name="mods_language_fork">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid">not provided</xsl:param>
    <xsl:param name="datastream">not provided</xsl:param>
    <xsl:param name="node" select="current()"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ '" />

    <xsl:call-template name="mods_authority_fork">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="value" select="$value"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>

    <!-- Fields are duplicated for authority because searches across authorities are common. -->
    <xsl:if test="@lang">
      <xsl:call-template name="mods_authority_fork">
        <xsl:with-param name="prefix" select="concat($prefix, 'lang_', translate(@lang, $uppercase, $lowercase), '_')"/>
        <xsl:with-param name="suffix" select="$suffix"/>
        <xsl:with-param name="value" select="$value"/>
        <xsl:with-param name="pid" select="$pid"/>
        <xsl:with-param name="datastream" select="$datastream"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Handle the actual indexing of the majority of MODS elements, including
    the recursive step of kicking off the indexing of subelements. -->
  <xsl:template name="general_mods_field">
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="value"/>
    <xsl:param name="pid"/>
    <xsl:param name="datastream"/>
    <xsl:param name="node" select="current()"/>

    <xsl:if test="$value">
      <field>
        <xsl:attribute name="name">
          <xsl:choose>
            <!-- Try to create a single-valued version of each field (if one
              does not already exist, that is). -->
            <!-- XXX: We make some assumptions about the schema here...
              Primarily, _s getting copied to the same places as _ms. -->
            <xsl:when test="$suffix='ms' and java:add($single_valued_hashset, string($prefix))">
              <xsl:value-of select="concat($prefix, 's')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($prefix, $suffix)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="$value"/>
      </field>
    </xsl:if>
    <xsl:if test="normalize-space($node/@authorityURI)">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'authorityURI_', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$node/@authorityURI"/>
      </field>
    </xsl:if>

    <xsl:apply-templates select="$node/*" mode="slurping_MODS">
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
      <xsl:with-param name="pid" select="$pid"/>
      <xsl:with-param name="datastream" select="$datastream"/>
    </xsl:apply-templates>
  </xsl:template>
  <!-- Delete non-explicit text in this mode -->
  <xsl:template match="text()" mode="cuhk_slurping_MODS"/>
</xsl:stylesheet>

