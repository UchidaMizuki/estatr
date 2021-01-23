
<!-- README.md is generated from README.Rmd. Please edit that file -->

# estatr

<!-- badges: start -->
<!-- badges: end -->

e-Stat
APIのクエリの作成・データのダウンロードを行うためのパッケージです．

**このサービスは、政府統計総合窓口(e-Stat)のAPI機能を使用していますが、サービスの内容は国によって保証されたものではありません。**

## インストール

CRAN上には公開されていないため，GitHubからインストールしてください．

    # install.packages("devtools")
    devtools::install_github("UchidaMizuki/estatr")

## データ取得の流れ

### estatオブジェクトの作成

    library(estatr)
    library(magrittr)
    library(dplyr)

    appId <- "Your own e-Stat appId"

    # estatオブジェクト作成例
    my_estat <- estat$new(statsDataId = "0003413193", 
                          appId = appId)
    #> このサービスは、政府統計総合窓口(e-Stat)のAPI機能を使用していますが、サービスの内容は国によって保証されたものではありません。

### データ概要の確認

必要に応じて`info`でデータの概要を確認できます．

    my_estat$info
    #> # A tibble: 17 x 2
    #>    name              value                                                      
    #>    <chr>             <chr>                                                      
    #>  1 STAT_NAME         "00200523_住民基本台帳人口移動報告"                        
    #>  2 GOV_ORG           "00200_総務省"                                             
    #>  3 STATISTICS_NAME   "住民基本台帳人口移動報告 参考表　2018年～　（転入・転出市区町村別結果（移動者（外国人含む），日本人移動者，外~
    #>  4 TITLE             "003_移動前の住所地別転入者数（移動者（外国人含む），日本人移動者，外国人移動者）　－都道府県，市区町村（平成3~
    #>  5 CYCLE             "年次"                                                     
    #>  6 SURVEY_DATE       "201901-201912"                                            
    #>  7 OPEN_DATE         "2020-04-28"                                               
    #>  8 SMALL_AREA        "0"                                                        
    #>  9 COLLECT_AREA      "該当なし"                                                 
    #> 10 MAIN_CATEGORY     "02_人口・世帯"                                            
    #> 11 SUB_CATEGORY      "04_人口移動"                                              
    #> 12 OVERALL_TOTAL_NU~ "220566"                                                   
    #> 13 UPDATED_DATE      "2020-12-24"                                               
    #> 14 STATISTICS_NAME_~ "住民基本台帳人口移動報告_参考表　2018年～　（転入・転出市区町村別結果（移動者（外国人含む），日本人移動者，外~
    #> 15 DESCRIPTION       ""                                                         
    #> 16 TITLE_SPEC        "移動前の住所地別転入者数（移動者（外国人含む），日本人移動者，外国人移動者）　－都道府県，市区町村（平成31年・令~
    #> 17 releaseCount      "1"

### 属性情報の確認

`key`や`value`で属性情報を確認できます．
表章項目が存在する場合に限り，`value`に表章項目が格納されます．

    names(my_estat$key)
    #> [1] "移動後の住所地(現住地)2019～" "国籍"                        
    #> [3] "移動前の住所地(前住地)2019～" "年次"
    my_estat$value
    #> # A tibble: 1 x 4
    #>   code  name                     level unit 
    #>   <chr> <chr>                    <chr> <chr>
    #> 1 11    他市区町村からの転入者数 ""    人

`key`や`value`には各属性情報がデータフレームで格納されます．
例として`key`の「移動後の住所地(現住地)2019～」の属性情報を示します．

    my_estat$key$"移動後の住所地(現住地)2019～"
    #> # A tibble: 1,964 x 4
    #>    code  name         level parentCode
    #>    <chr> <chr>        <chr> <chr>     
    #>  1 01000 北海道       2     00005     
    #>  2 01100 札幌市       3     01000     
    #>  3 01101 札幌市中央区 4     01100     
    #>  4 01102 札幌市北区   4     01100     
    #>  5 01103 札幌市東区   4     01100     
    #>  6 01104 札幌市白石区 4     01100     
    #>  7 01105 札幌市豊平区 4     01100     
    #>  8 01106 札幌市南区   4     01100     
    #>  9 01107 札幌市西区   4     01100     
    #> 10 01108 札幌市厚別区 4     01100     
    #> # ... with 1,954 more rows

### 属性情報の絞り込み

`key`や`value`のデータフレームを上書きすることにより自動的に（`cdCat01`などの）クエリが作成できます．
データの上書きに`magrittr`パッケージの`%<>%`を使用することで，プログラムをシンプルにしています．

    # データ絞り込み例
    my_estat$key$"移動後の住所地(現住地)2019～" %<>%
      filter(name == "北海道")
    my_estat$key$"国籍" %<>%
      filter(name == "移動者")
    my_estat$key$"移動前の住所地(前住地)2019～" %<>%
      filter(level == "2")

    # `key`の絞り込みをやり直したい場合には，`restore_key()`メソッドを実行（全てのkeyが初期化される）．
    # my_estat$restore_key()

    # 同様に，`restore_value()`で`value`の絞り込みが初期化されます．

### データ取得

`get_data()`メソッドを実行するとデータが取得・出力されます．同時に`data`にデータが格納されます．

    my_estat$get_data()
    #> The total number of data is 38.
    #> Downloading data from lines 1 to 100000
    #> # A tibble: 38 x 15
    #>    `code_移動後の住所地(現~ code_国籍 `code_移動前の住所地(前~ code_年次 `name_移動後の住所地(現~
    #>    <chr>            <chr>     <chr>            <chr>     <chr>           
    #>  1 01000            60001     01000            20190000~ 北海道          
    #>  2 01000            60001     02000            20190000~ 北海道          
    #>  3 01000            60001     03000            20190000~ 北海道          
    #>  4 01000            60001     04000            20190000~ 北海道          
    #>  5 01000            60001     05000            20190000~ 北海道          
    #>  6 01000            60001     07000            20190000~ 北海道          
    #>  7 01000            60001     08000            20190000~ 北海道          
    #>  8 01000            60001     09000            20190000~ 北海道          
    #>  9 01000            60001     10000            20190000~ 北海道          
    #> 10 01000            60001     11000            20190000~ 北海道          
    #> # ... with 28 more rows, and 10 more variables: name_国籍 <chr>,
    #> #   `name_移動前の住所地(前住地)2019～` <chr>, name_年次 <chr>,
    #> #   `level_移動後の住所地(現住地)2019～` <chr>, level_国籍 <chr>,
    #> #   `level_移動前の住所地(前住地)2019～` <chr>, level_年次 <chr>,
    #> #   `parentCode_移動後の住所地(現住地)2019～` <chr>,
    #> #   `parentCode_移動前の住所地(前住地)2019～` <chr>,
    #> #   他市区町村からの転入者数_人 <dbl>
