--=========================================================
--Ad hoc report request involving Producer data.
--=========================================================


--=========================================================
--Step 1: Declare variables that will serve as constraints.
--Note: Values will change according to request.
--=========================================================
DECLARE @BeginDate varchar(10) = <VALUE>,
        @EndDate varchar(10) = <VALUE>,
        @State char(2)= <VALUE>,
        @GroupSize tinyint(1) = <VALUE>,
        @FundTyp varchar(10) = <VALUE>,
        @ProdCat char(1)= <VALUE>
--=========================================================
--Step 2: Establish a list of Producers, as well as their respective Class Plan,
        --Product, and Group Identifiers.  The Billing and Commission
        --amounts associated with the sale of those products are also listed.
--=========================================================
SELECT a.COCE_ID,
       b.COCE_NAME,
       a.CSPI_ID,
       a.PDPD_ID,
       c.GRGR_CK,
       c.GRGR_ID,
       a.COEC_SOURCE_AMT,
       a.COEC_COMM_AMT_PAID
INTO #temptable1
FROM db1.dbo.table1 a
JOIN db1.dbo.table2 b ON a.COCE_ID = b.COCE_ID
JOIN db1.dbo.table3 c ON a.BLEI_CK = c.BLEI_CK
WHERE a.BLBL_DUE_DT BETWEEN @BeginDate AND @EndDate AND
      b.COCE_TERM_DT >= @BeginDate AND
      c.BEIN_TERM_DT >= @BeginDate
--=========================================================
--Step 3: Establish a list of Groups, as well as their respective State and
        --Group Size values.
--=========================================================
SELECT DISTINCT d.GRGR_CK,
                d.GRGR_ID,
                d.ELE_VALUE AS STATE,
                e.ELE_VALUE AS GRP_SIZ
INTO #temptable2
FROM db2.dbo.table4 d, db2.dbo.table4 e
WHERE d.GRGR_CK = e.GRGR_CK AND
      d.GRGR_ID = e.GRGR_ID AND
      d.ELE_TERM_DT >= @BeginDate AND
      e.ELE_TERM_DT >= @BeginDate AND
      d.ELEMENT = <VALUE> AND
      e.ELEMENT = <VALUE> AND
      d.ELE_VALUE = @State AND
      e.ELE_VALUE = @GroupSize
--=========================================================
--Step 4: Establish a list of Groups, as well as their respective Class Plan
        --identifiers, Product Categories, and Funding Types.
--=========================================================
SELECT DISTINCT GRGR_CK,
                CSPI_ID,
                CSPD_CAT,
                ELE_VALUE
INTO #temptable3
FROM db2.dbo.table5 f
WHERE f.ELEMENT = <VALUE> AND
      f.ELE_TERM_DT >= @BeginDate AND
      f.ELE_VALUE = @FundTyp
--=========================================================
--Step 5: Establish a more complete composition of Producer Billing and
        --Commissions data.
--=========================================================
SELECT g.COCE_ID,
       g.COCE_NAME,
       g.CSPI_ID,
       g.PDPD_ID,
       (CASE WHEN h.PLDS_DESC LIKE <VALUE> THEN NULL
	     WHEN h.PLDS_DESC LIKE <VALUE> THEN NULL
	     WHEN h.PLDS_DESC LIKE <VALUE> THEN NULL
             ELSE h.PLDS_DESC
	END) AS PLDS_DESC,
       j.CSPD_CAT,
       g.GRGR_CK,
       g.GRGR_ID,
       g.COEC_SOURCE_AMT,
       g.COEC_COMM_AMT_PAID,
       i.STATE,
       i.GRP_SIZ,
       j.ELE_VALUE
INTO #temptable4
FROM #temptable1 g
JOIN db1.dbo.table6 h ON g.CSPI_ID = h.CSPI_ID
LEFT JOIN #temptable2 i ON g.GRGR_ID = i.GRGR_ID
LEFT JOIN #temptable3 j ON g.GRGR_CK = j.GRGR_CK AND
                           g.CSPI_ID = j.CSPI_ID
DROP TABLE #temptable1, #temptable2, #temptable3
--=========================================================
--Step 6: Aggregate Producer Billing, Commission, Policy, and Member data.
--=========================================================
SELECT k.STATE,
       k.GRP_SIZ,
       k.ELE_VALUE,
       k.COCE_ID,
       k.COCE_NAME,
       k.CSPD_CAT,
       SUM(k.COEC_SOURCE_AMT) AS PREM_AMT,
       SUM(k.COEC_COMM_AMT_PAID) AS COMM_AMT,
       subquery2.PLCY_CNT,
       subquery5.MEM_CNT
FROM #temptable4 k
JOIN (SELECT STATE,
             GRP_SIZ,
             COCE_ID,
             CSPD_CAT,
             SUM(PLCY_CNT) AS PLCY_CNT
       FROM (SELECT DISTINCT STATE,
                             GRP_SIZ,
                             COCE_ID,
                             CSPI_ID,
                             CSPD_CAT,
                             COUNT(DISTINCT PLDS_DESC) AS PLCY_CNT
             FROM #temptable4
             GROUP BY STATE, GRP_SIZ, COCE_ID, CSPI_ID, CSPD_CAT) AS subquery1
	GROUP BY STATE, GRP_SIZ, COCE_ID, CSPD_CAT) AS subquery2 ON k.STATE = subquery2.STATE AND
	                                                            k.GRP_SIZ = subquery2.GRP_SIZ AND
	                                                            k.COCE_ID = subquery2.COCE_ID AND
							            k.CSPD_CAT = subquery2.CSPD_CAT
JOIN (SELECT subquery3.STATE,
             subquery3.GRP_SIZ,
             subquery3.COCE_ID,
             subquery3.CSPD_CAT,
             COUNT(MEME_CK) AS MEM_CNT
      FROM (SELECT DISTINCT STATE,
                            GRP_SIZ,
                            COCE_ID,
                            GRGR_CK,
                            CSPI_ID,
                            PDPD_ID,
                            CSPD_CAT
            FROM #temptable4) AS subquery3
      LEFT JOIN (SELECT DISTINCT GRGR_CK,
                                 CSPI_ID,
                                 PDPD_ID,
                                 CSPD_CAT,
                                 MEME_CK
                 FROM db1.dbo.table7
                 WHERE MEPE_TERM_DT >= @BeginDate AND
	               MEPE_ELIG_IND = <VALUE> AND
		       CSPD_CAT IN (<VALUES>)) AS subquery4 ON subquery3.GRGR_CK = subquery4.GRGR_CK AND
	                                                       subquery3.CSPI_ID = subquery4.CSPI_ID AND
					                       subquery3.PDPD_ID = subquery4.PDPD_ID AND
							       subquery3.CSPD_CAT = subquery4.CSPD_CAT
      GROUP BY subquery3.STATE, subquery3.GRP_SIZ, subquery3.COCE_ID, subquery3.CSPD_CAT) AS subquery5 ON k.STATE = subquery5.STATE AND
	                                                                                                  k.GRP_SIZ = subquery5.GRP_SIZ AND
	                                                                                                  k.COCE_ID = subquery5.COCE_ID AND
										                          k.CSPD_CAT = subquery5.CSPD_CAT
WHERE CSPD_CAT = @ProdCat
GROUP BY k.STATE, k.GRP_SIZ, k.ELE_VALUE, k.COCE_ID, k.COCE_NAME, k.CSPD_CAT, subquery2.PLCY_CNT, subquery5.MEM_CNT
ORDER BY k.COCE_NAME
DROP TABLE #temptable4
