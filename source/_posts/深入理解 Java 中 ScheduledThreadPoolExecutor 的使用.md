---
title: 深入理解 Java 中 ScheduledThreadPoolExecutor 的使用
title_url: understand-Java-ScheduledThreadPoolExecutor-usage-practice
date: 2019-10-14
tags: [Java]
categories: Java
description: 本文将详细分析 ScheduledThreadPoolExecutor 的使用，1. ScheduledThreadPoolExecutor 的初始化 2. scheduleWithFixedDelay 方法和 scheduleAtFixedRate 方法详解 3. 使用场景分析
---

## 1 概述

本文将详细分析 ScheduledThreadPoolExecutor 的使用，具体内容如下

1. ScheduledThreadPoolExecutor 的初始化
2. scheduleWithFixedDelay 方法和 scheduleAtFixedRate 方法详解
3. 使用场景分析

## 2 ScheduledThreadPoolExecutor 的初始化

首先看看 ScheduledThreadPoolExecutor 的类图

![image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAeYAAAGrCAYAAAAVVTR9AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAACNXSURBVHhe7d3vjyRnYeDx+Wv8ZgQCceJeICYJCpwwTrQ5ZcBLEn4tibmDF7m1GUSWaALegyE4J62NJdsbXgAHLya3kQDJ1umCQZzhBPbexuxsDDHih+OTZd4AL4J9h6W6fqq7pquqn6runumZebqezyN95J2uH91V3VXfeWbH9kZxzPHCC0Xx279dFDduTB4wDMMwDOPI49hh/slPRjsZ7eUb35g8YBiGYRjGkYcwG4ZhGEZC49hhNgzDMAxjdUOYDcMwDCOhIcyGYRiGkdAQZsMwDMNIaAizYRiGYSQ0hNkwDMMwEhrCbBiGYRgJDWE2DMMwjISGMBuGYRhGQkOYDcMwDCOhIcyGYRiGkdAQZsMwDMNIaAizYRiGYSQ0hNkwDMMwEhrCbBiGYRgJDWE2DMMwjISGMBuGYRhGQkOYDcMwDCOhIcyGYRiGkdAQZsMwDMNIaAizYRiGYSQ0hNkwDMMwEhrCbBiGYRgJDWE2DMMwjITGxubmZgEApEGYASAhwgwACRFmAEiIMANAQoQZABIizACQEGEGgIQIMwAkRJgBICHCDAAJEWYASIgwA0BChBkAEiLMAJAQYQaAhAgzACREmAEgIcIMAAkRZgBIiDADQEKEGQASIswAkBBhBoCECDMAJESYASAhwgwACRFmAEiIMANAQoQZABIizACQEGEGgIQIMwAkRJgBICHCDAAJEWYASIgwk7Wtra1iZ2eHRFy4cCH6PkFOhJmsnTt3rrh27Vo0Epyuvb294urVq9H3CXIizGQthDnEoCieJwHCDMJM5oQ5LcIMwkzmhDktwgzCTOaEOS3CDMJM5oQ5LcIMwkzmhDktwgzCTObmhfnlV35U3Hjxq8XXnn2w+NKtT5XCn8NjYVlsG45OmEGYyVxfmH/6yyeKL9/aKz5/896osCysE9uWoxFmEGYy1xXmENwvHFyOBrkurHMacd7f3ig2NuruKPYj652Ox4vdzY1iez+27HiEGYSZzMXC/NJvnu2dKbeFdcM29X0EN3/+WPHIjUvFwyPXX/jKzPJlhDCfRAiPRpjhJAkzWYuFOfz9cTu+b337VkN7edimvo8gBPkXL90sfvXyreLB6zszy5fRGeb9O8oZ9HTZQ8X26OvN3cfHXx9cLDZrM+32Ppoz8WoWHvZRm5GX+xh/fbB7W239ym3F7kF93emy+vOVx7BbXz476xdmEGYyFwtz+OWudniDD+2dL8WWhW3q+wiuPHlP7c93N5Yta+ZH2ZsXi4NqeRnnceTCeodRbge2/Hoa0XKf2w9NltV1h3m8vGPGXK7XjnTr+Wqvuwx1ax/CDMJM5mJh7voxdl+Ywzb1fQT3PzUOc4hyTHv9PrGI1R3OZOuhbc1ex6pQNiPddLQwl6+hFfr66553DIEwgzCTuZMMcyUW5SC2bpdFwry52QpjmEnXZ9YNwgypEmaydpI/yq7EohzE1u3SG7XDAI+D2fxRdtd243W7f5RdRXuyXiPM49czfZ6JBX6ULcwwnzCTtZP85a9KLMpBbN0uIWrNH0lPQln+/XI7ht2//NWcQVfRrUzjW/8lr83di80ZdNDYb+35J7+MNvP4iDDDYoSZrMXCvKp/XaoSi3IQWzd3wgzCTOZiYQ5S+w+M5EKYQZjJXFeYgxDcvplzWCbKqyXMIMxkri/Mgf+JxekSZhBmMjcvzJwuYQZhJnPCnBZhBmEmc8KcFmEGYSZzIczXrl0rdnZ2OGN7e3vCDCPCTNa2traikVg393z0YvTxdXPhwoXo+wQ5EWYYgH//kbcU//ZNr4suA9aLMMOaC0F+zwPnyjjHlgPrRZhhzYUghzAHZs2w/oQZ1lg1W66YNcP6E2ZYY/XZcsWsGdabMMOaas+WK2bNsN6EGdZUbLZcMWuG9SXMsIa6ZssVs2ZYX8IMa6hvtlwxa4b1JMywZubNlitmzbCehBnWzCKz5YpZM6wfYYY18urXvKp4y7u3ZoQIxx5/w+2vj+4HSJcwwwCEMMceB9aPMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMMMACDMMhzDDAAgzDIcwwwAIMwyHMJO0CxcuFDs7O8zxwcvO06K2trainzVIhTCTtKtXrxZ7e3vRGyws69q1a8W5c366QNqEmaSFMBfF87AS4fMkzKROmEmaMLNKwsw6EGaSJsyskjCzDoSZpAkzqyTMrANhJmnCzCoJM+tAmEmaMLNKwsw6EGaS1hfml1/5UXHjxa8WX3v2weJLtz5VCn8Oj4VlsW3ImzCzDoSZpHWF+ae/fKL48q294vM3740Ky8I6sW1ZAwcXi82NjWJ7P7LsGISZdSDMJC0W5hDcLxxcjga5LqxzGnHe394oNkYRmbqj2I+sdzoeL3Y3Vxy0SSQPj2/7ofh6qyTMZEyYSVo7zC/95tnemXJbWDdsU99HcPPnjxWP3LhUPDxy/YWvzCxfRgjzqgNydCsOcxnI24rdg8iyNSTMrANhJmntMIe/P27H961v32poLw/b1PcRhCD/4qWbxa9evlU8eH1nZvkyOsO8f0c5w5wue6jYHn29ufv4+OvWTLS9j+ZMvJqFh33UZuTlPsZfH+zeVlu/Uotqz/OVx7BbXz55jnlhPsI+y9e5ebE4qPYxWbc6L/Xjjp3X+HkZmXM+A2FmHQgzSWuHOfxyVzu8wYf2zpdiy8I29X0EV568p/bnuxvLltUMxUg9OmWcx/Gox2cmsOXX0wCW+4z+yLg7zOPlHTPmdmBbX5fPV3vd4etqH4fBb8V0oWOI7rO53ux+gvhxLHxeZp5jTJhZB8JM0tph7voxdl+Ywzb1fQT3PzUOc4hyTHv9PvWIxRyGrR6U1uxurApJPCpjrQAtGObyNbSCVn/d844hmAl07zH07zMsq75Jib22+HH0nJc5r6UizKwDYSZpJxXmSizKQWzdLouEeXOzFZ8wk56ZgVbSDPNYeP7Jur3HMGef4XWX24bXGzvWJcM857VUhJl1IMwkrR3mVf0ouxKLchBbt0tvgA6DMQ5N80fZXduN152dRQb1OE3Wa4R5/HqmzzNRBrwWtdbXC4e5sV3fMczb5yTI+1WgY8vb2887L/OPQZhZB8JM0tphXtUvf1ViUQ5i63YJAWr+CHUSyvLvl9sxrEVz8vXhdo1AVdGtTON7+CPlkc3di6MgNcPc3G/t+cvXE3l8pDOijW3GGuv1HMPc2E/2HY1vfZ+NdbrPS//5HBNm1oEwk7R2mFf1r0tVYlEOYuuy/oSZdSDMJK0d5iC1/8AI60OYWQfCTNJiYQ5CcPtmzmGZKNMmzKwDYSZpXWEO/E8sWJYwsw6EmaT1hRmWJcysA2EmacLMKgkz60CYSZows0rCzDoQZpIWbqR7e3vFzs4OHNu1a9eEmeQJM0m7cOFC9AZ7lu756MXo4zR9+CP3lGLLztLW1lb0swapEGZYwqtf86rizntvL/8ZW87Um//kjaXYMqCbMMMSQmje88A5wZkjfOPyx5/5vZJvYmA5wgwLqmITwiw4/apvYHwTA8sTZlhQPTaC063+DUzgmxhYjjDDAtqxEZxu7W9gAt/EwOKEGRYQi43gzIp9AxP4JgYWJ8wwR1dsBGdW1zcwgW9iYDHCDHP0xSYQnLG+b2AC38TAYoQZesyLTSA4Y/O+gQl8EwPzCTP0WCQ2Qe7BWeQbmMA3MTCfMEOHRWMT5B6cRb+BCcyaoZ8wQ4d/88bXFm9599aMEJfY42H92H5y8KZ3vCF6TmLnKqwb2wcwJsywpBCb2OPMcq5gecIMSxKbxTlXsDxhhiWFH8fGHmeWMMPyhBk4McIMyxNmWJIZ8+KEGZYnzLAksVmccwXLE2ZYktgszrmC5QkzLElsFudcwfKEGZYkNotzrmB5wgxLEpvFOVewPGGGJfmt7MUJMyxPmIETI8ywPGHOXLhxtlUzwvBPy7uXM1/s/DFf7FySD2HOnMhAWoQZYQZIiDAjzJkzY4a0CDPCnDk3AUiLaxJhzpybAKTFNYkwZ85NANLimkSYM+cmAGlxTSLMmXMTgLS4JhHmzPmtbEiLMCPMAAkRZoQ5c2bMkBZhRpgz5yYAaXFNIsyZcxOAtLgmEebMuQlAWlyTCHPm3AQgLa5JhDlzbgKQFtckwpw5v5UNaRFmhBkgIcKMMGfOjBnSIswIc+bcBCAtrkmEOXNuApAW1yTCnDk3AUiLaxJhzpybAKTFNYkwZ85NANLimuTUwryzs0OCPnj5QvRxzl7sOjqO2HOQHtfkeohdY6tyamH+5je/GT04YFa4XmLX0XG4BmE1TuL6rDvVMBfF88ACTirMsecCliPMkCFhhnQJM2RImCFdwgwZEmZIlzBDhoQZ0iXMkCFhhnRlEeaXXnm+eOLF54ovPvtc8cA//awU/hweC8ti28CQnXaYX37lR8WNF79afO3ZB4sv3fpUKfw5PBaWxbaBXGUR5s+OQvxfDuLCstg2p+uhYnvjjmI/uoysHVwsNjc2iu39yLJjOM0w//SXTxRfvrVXfP7mvVFhWVgntm0aVnR9lu/lYvvZ394oNkbve3Dk936J5+OI1uj6rDvTMP+fF58p/xkLcl193RO3f0d5sW3uPl57/DgX/uPF7ubqPxjdup+vfjMZO8ubwgmcl8lFeHh82w/F11ulNQ9zCO4XDi5Hg1wX1jmVOB/pPTz9MI8d8zPcej7X5wlYo+uz7szC/H//38+Kr379H8o/x2JcF9YJ64Zt6vsIbv78seKRG5eKh0euv/CVmeXL2t++rdjdH72ZmxeLg8PHhxPm03sd86z4vJQX4Oi9O4gsW0OnEeaXfvNs70y5LawbtqnvI1jZNXjk93A4YXZ9rofBhvmfnr1R/P1//x/ln0N8P/P9nxT/4bOfK972/v9YvOX8u4o7P/KXxSe+8dRhmMO6YZv6PoJwM/jFSzeLX718q3jw+s7M8uWMLvAyyOFDWf8QTS78yWw6aMyoyw/d9DvBatnB7m2Hj01N91teiLv1bZsXaX279gXSXD7ebqHni11ok+OaLgvHWzvG1vEt8lpmbpa1m9C819n3fJ3nbN6Ff4R9lq+z8Q3aeN3qvNSPO3Ze4+dlZM75DE4jzOHvj9vxfevbtxray8M29X0EK7sG572HI/Fzutz12TjfrWWLfH4Pt+2K15Geb/I5jHwWXJ/xfQ7t+qw7szB//TvfaoT5rvuvFu+8dLn45P+6WXz6f/+w+PB/e7TY++4zjTCHber7CK48eU/tz3c3li1tdAFUb2p406cX9/hCOPzRS+tDVn5wIm/eWPd3nuUHo/bB6txP+XzTD065XeePgeY8X+0D1/hQlxf/+DnCes1jr31oy6+bxx5/Ld0X/nh5302tfRNoPV/HOTu8obQu1oWOIbrP5nqz+wnix7HweZl5jrHTCHP45a52eIMP7Z0vxZaFber7CFZ5DXa/h/POaW1Z7bPcf77H2x2+d43PaGu7mc9vEHvvj/p8k+MLx1FxfZZfd++zud7sfoL1uT7rzizMX/2HrzfC/Lb3f6D45Hduln9uC+uEdcM29X0E9z81vimEG0JMe/1urTcwfOAOPwztN6u57uEHLvpGd3zAR+of2hmT75KnquePf1Cmjvh8I9HjKC+8+usIqufvey2tc7bghV++htZ5rL/ueccQzNwAeo+hf59hWf2btdn3OHYcPedlzmupnEaYu36M3RfmsE19H8HqrsGpmffwqJ+1vvMdrrF6JBqf0Xmf3yDy3h/5+Vyf8WPI5/qsSyzMT89EOQjrdIW5ErshBLF1o+Z+wOd/aA9j2vhwdKw70v2Ba31wGhdN38UWHOX5xsIHe3Oz9eFu30wa+l5L65yd4oU/Fp5/sm7vMczZZ3jd5bbh9caONXYcPedlzmuprFOYK7HrL4itu5jae3jUz1rf+W4vm7nO+j6/QeS9P/LzuT7jx5DP9VmX0I+yHynOX/p4Gee97/2g+E//9e+Lv3zsfzbCHPtRdiV2Qwhi68bEPnDlhVB+N9b6EIc3b+YinYhcwOGDNf3RU/Px6Aeu3Mf0gxPWmz7f+IPWfq11Sz9fcPiBHO9/un3tAmpv0/ta6h/+yXqLnJfWscfORecx1DW26zuGefsMr320n5lfCKwvb28/77zMP4bTCPOqfpRdiV1/QWzdhTTew3nntPbZKrervu4537H9N7brWlaJvfdHfT7XZ9d2uVyfdcn88td9T/+4jPPbLnyg+HfvfFfxzkufKP7zt8cz6LBOWDf2y1+V2A0hiK07K/bmjRwGePxmzc6kg+pDPTWzn/JDOLtt3wcuLKv2t7l7cfT89Yum/ZytG0bP8023CSbblcdZO6bJ9ocXZWN/I40LoPu1lN/sTB6fPYaRjtc5fj2Rx0c6z1ljm7HGej3H0H/hj0z23Vxn9n1vrtPzHvWez7HTCPOqfvmrErv+gti6UfPew85zGq7P9vld7HzXP6Pb+839dH9+57z3R3w+12dteYbXZ92ZhXlV/7pUJXZDCGLrQupOI8yr+telKrHrL4itC+tssGEOkvwPjEACTiPMQXL/gRFYA4MOcyX9/yQnnK7TCnMQgts3cw7LRBmmsgiz/4kFNJ1mmAP/EwtYXBZhBppOO8zA4oQZMiTMkC5hhgwJM6RrUGHe2dkBFnBSYY49F7CcwYQ5dnCcvbv/4t7o45y92HV0HLHnIC0f/sg9pdgy0hK7xlbl1MJMel712tcXf3DfM+U/Y8uB0/XmP3ljKbaMfAhzxn7nvfcVd37u1+U/Y8uB0/Pq17yq+OPP/F4p/Dm2DnkQ5kyFWfIffvaFMszhn2bNcLbCTPk9D5wrmTXnTZgzVc2WK2bNcHaq2XIVZrPmvAlzhuqz5YpZM5yd+my5YtacL2HOUHu2XDFrhtPXni1XzJrzJcyZic2WK2bNcPpis+WKWXOehDkzXbPlilkznJ6u2XLFrDlPwpyRvtlyxawZTk/fbLli1pwfYc7IvNlyxawZTt682XLFrDk/wpyJRWbLFbNmOHmLzJYrZs15EeZMvO63fr940/uvzAghjj0e1o/tB1iNN73jDcVb3r01I4S4/VhYN7YPhkmYMxfCHHscOBshzLHHyYcwZ06YIS1hhhx7nHwIc+aEGSAtwpw5YYa0mDEjzJkTZkiLv2NGmDMnzJAWYUaYMyfMkBZhRpgzJ8yQFmFGmDMnzJAWYUaYMyfMkBa/lY0wZ06YAdIizJkTZkiLGTPCnDlhhrT4O2aEOXPCDGkRZoQ5c8IMaRFmhDlzwgxpEWaEOXPCDGkRZoQ5c8IMafFb2Qhz5oQZIC3CnDlhhrSYMSPMmRNmSIu/Y0aYMyfMkBZhRpgzJ8yQFmFGmDMnzJAWYUaYMyfMkBZhRpgzJ8yQFr+VjTBnTpgB0iLMmRNmSIsZM8KcOWGGtPg7ZoQ5c8IMaRFmhDlzwgxpEWaEOXPCDGkRZoQ5c8IMaRFmhDlzwgxp8VvZCHPmhBkgLcKcOWGGtJgxI8yZE2ZIi79jZq3CfO7cuWJnZ4cVuuvTj0Yf5+jC5zT2+YVFCDNrFeZw07t69erMjRBSUX0+Y59fWIQws3ZhDorieUhS9RmNfX5hEcKMMMMKCTPHJcwIM6yQMHNcfisbYYYVEmbguIQZVkiYOS4zZoQZVkiYOS5/x8ygwvzrV54vnnjxueILzz5XXLn1s1L4c3gsLIttA6skzByXMDOYMP/wl/9S3D8K8X0348KysE5s29PzULG9cUexH112Cg4uFpsn/Pz72xvFxsbY9n58nSETZo5LmBlEmENw/+YgHuS6sM5Jx/lg97bDMNVt7j4+Wp5SmMNrab7G1YX08WJ3c3Z/9WiPneG56HiNxyXMHJcws/Zh/tff9M+U28K6YZv6PoKbP3+seOTGpeLhkesvfGVm+fJiEU4tzLXXUi67rdg9mHx9LN1hTmcWLcykSZhZ+zCHvz+uh/evn/5xcdcDf1vc/r4PFL/7jj8q3v7hjxUf/8aTjXXCNvV9BCHIv3jpZvGrl28VD17v/nvsxfWEef+Ow1njeCY9Xl6GazcEMjKjLMNZPd4MSnsm2ohNa7vpPtuvrxWqnufrXVZaMsyT8zFdFl5b7dzMeb7m8XccX7mP8dfxn2rUvinpeb7e92hEmDkuv5XN2oc5/HJXPbp/euWR4vylTxSXv/P9Yu/6Pxf3/N2jxSe/+0xjnbBNfR/BlSfvqf357sayo+kK8+hmvv3Q+OsySNN1ysBsXiwOal+Po9DeV/i6Y3ZbC1D1fIdhmVlW22f5Wib7LNdrh2qBZdW+esI8DWHzWOvnIqw3/Yal/9jLfVbns6G1XePYg44Z85zj636PxoQZOK61D3P7x9i3v++u4vK3v994rC1sU99HuZ+nxmEOUY5prz9fOyiRx1qxaN/kD5Xr1YJWqsWjNgMfm+wzPF6PX+P5wmupbzPdXzmjbMWuem19y6aPLTljnjicydb333vszUg3HS3M845v3jEIM8dlxsxAw/x047G2WJgrsSgHsXX7rTDM7cA2tOJU3+fcMLdf39hZhnlzs7X/ZY59Zln3uRZmUuXvmBngj7IfLu786F+Vcf7U935Q/PkXrxUfe/RbjXViP8quxKIcxNbtFwtffyy6b/phu45l5T6mcQr7OJwxN5aNQzT90Xns9U209tn4um/Z4T6OEObDAI+3bf4ou2u7yTG1QjoWtus69rHweup/x1+ac3zCzEkTZgb5y18hzre/98+KN59/V3H+0seLe5/4x8Y6sV/+qsSiHMTW7RcLX+ux8qY//br3pl+uG+IyUZtFjmM8trl7sfEc5Qxwsmx7v/78sddXE0I52a7xY/PeZVUAm6pjqr/Oscnzl/trx7D7l7+aM+j2c8aPvX1eZvdbe/6eYxdmTpows/ZhXtW/LlWJRTmIrQttwsxxCTNrH+Ygpf/ACHkTZo5LmBlEmIMQ3L6Zc1gmypw0Yea4/FY2gwlz4H9iwVkTZuC4BhVmOGvCzHGZMSPMsELCzHH5O2aEGVZImDkuYWbtwnz16tXDmx+kpvp8xj6/sAhhZq3CfO7cuZkbIcdz91/cG32cowuf09jnFxYhzKxVmFmtV7329cUf3PdM+c/YcuD0CTPCnLHfee99xZ2f+3X5z9hy4PT5rWyEOVNhlvyHn32hDHP4p1kzQBqEOVPVbLli1gxpMGNGmDNUny1XzJohDf6OGWHOUHu2XDFrhrMnzAhzZmKz5YpZM5w9YUaYM9M1W66YNcPZEmaEOSN9s+WKWTOcLWFGmDMyb7ZcMWuGs+O3shHmTCwyW66YNQOcHWHOxOt+6/eLN73/yowQ4tjjYf3YfoCTZcaMMGcuhDn2OHA2/B0zwpw5YYa0CDPCnDlhhrQIM8KcOWGGtAgzwpw5YYa0CDPCnDlhhrT4rWyEOXPCDJAWYc6cMENazJgR5swJM6TF3zEjzJkTZkiLMCPMmRNmSIswI8yZE2ZIizAjzJkLYR662HGzvkK42qpfmAr/HMLy8GfyJcwMmjAPTxUxGCphZtCEGVg3wsygCfPwmDEzdMLMoAnz8Pg7WIZOmBk0YR4eYWbohJlBE+bhEWaGTpgZNGEeHmFm6ISZQRPm4RFmhk6YGTRhHh6/lc3QCTODJszAuhFmBk2Yh8eMmaETZgZNmIfH3zEzdMLMoAnz8AgzQyfMDJowD48wM3TCzKAJ8/AIM0MnzAyaMA+PMDN0wsygCfPw+K1shk6YGTRhBtaNMDNowjw8ZswMnTAzaMI8PP6OmaETZgZNmIdHmBk6YWbQhHl4hJmhE2YGTZiHR5gZOmFm0IR5eISZoRPmTF24cKHY2dkZvLs+/Wj0cdbXBy/n8dnd2vLb57kS5kxdvXq12Nvbi94QgLN17dq14tw5PxnIlTBnKoS5KJ4HEhSuT2HOlzBnSpghXcKcN2HOlDBDuoQ5b8KcKWGGdAlz3oQ5U8IM6RLmvAlzpoQZ0iXMeRPmTPWF+devPF888eJzxReefa64cutnpfDn8FhYFtsGWB1hzpswZ6orzD/85b8U949CfN/NuLAsrBPbNg0PFdsbdxT70WVLOLhYbC64n/3tjWJjY2x7P77OXAs/34qO76iWOC9HtZLzueaEOW/CnKlYmENw/+YgHuS6sM6pxLmMwPQmvbH9UHy9htMP89jjxe7masJ8sHvb9JhrNncfH62bUpjDa2m+xtWFNH4+69EeO8Nzcdz3vIcw502YM9UO87/+pn+m3BbWDdvU9xHc/PljxSM3LhUPj1x/4SszyxdWBuC2YvcgsqzX+od5+njsWFILc+21HPk9i+kO80mE8GiEmZMhzJlqhzn8/XE9vH/99I+Lux742+L2932g+N13/FHx9g9/rPj4N55srBO2qe8jCEH+xUs3i1+9fKt48PrOzPKFLXCTb86eWrHYv+Nw2XimOdmu3O90u8ZNtbVsZp+N9Wpflzpu0kd6vkpPmDuOrwzXbn2/7dddPd58Le2Z6JHOS/scLHHsjWWlJcM8OR/TZeG11c7NnOfr/SxV65X7GH8d/6lG7fPa83y979GEMOdNmDPVDnP45a56dP/0yiPF+UufKC5/5/vF3vV/Lu75u0eLT373mcY6YZv6PoIrT95T+/PdjWXLOrz5bV4sDlrLyhtp9Efb4xvy4bLyht1xoy2/rm6m4+0Ob6C1m3DfDXq8nyAWkqM+X6W9ffVY1/FNzkvtfE1D1vdaWmaOfcHzUr6WyT7L9dqhWmBZta+eMFexm/ls1M5FWG/6DUv/sfd/lmrbNY496PtmrPv4ut+jKWHOmzBnqh3m9o+xb3/fXcXlb3+/8Vhb2Ka+j3I/T43DHKIc015/EbOBbt5Ym3pupuWfJzf0Q5P9hJt6/SbfuAnPu0EHkZv0kZ+v0nre2GOt7WI3+el6Ha8lLC+jVl822efc81LfZrq/8j1rxa56bX3Lpo8tOWOeOPys1Pffe+zhGGrnoWHe+x5/jfOOb94xBMKcN2HO1GJhfrrxWFsszJVYlIPYuosZR2B8QzvizbQdmbqTCPORn6/Set7YY63tOm/6fa+lfT77zlnfeak5yzBvbrb2v8yxzyzrPtfCzEkR5ky1wzz7o+yHizs/+ldlnD/1vR8Uf/7Fa8XHHv1WY53Yj7IrsSgHsXUXUt4Uqxvo+IbYvvmN9d1Mw7KOm2Js/43tupZVYjfpoz5fpXUsscdasei+6S/6Wsb7OHwtc89L+/VNtPbZ+Lpv2eE+YudzTtQOAzzetvmj7K7tJsfU+VnqOvax8Hoav8MQzDk+YWYeYc5UO8yxX/4Kcb79vX9WvPn8u4rzlz5e3PvEPzbWif3yVyUW5SC2blS4yY5upnXNm1l1o6x0xKK8Kba/rm1Xm0mVM53J49v7zf3Ul23uXqwta7+OavvjPd/YAo+1jq/3pt/zWsYxHmseX9/rjL2+msZ72Apv57L+81l/nWOT5y/3145hLZo9x979Wep73yca+609f8+xCzPzCHOm2mFe1b8uVYlFOYitCzQJc96EOVPtMAfJ/QdGIFPCnDdhzlQszEEIbt/MOSwTZThZwpw3Yc5UV5gD/xMLOFvCnDdhzlRfmIGzJcx5E+ZMCTOkS5jzJsyZEmZIlzDnTZgzFS78vb29YmdnB0jMtWvXhDljwpypCxcuRG8IQBq2trai1y7DJ8wAkBBhBoCECDMAJESYASAhwgwACRFmAEiIMANAQoQZABIizACQEGEGgIQIMwAkRJgBICHCDAAJEWYASIgwA0BChBkAEiLMAJAQYQaAhAgzACREmAEgIcIMAAkRZgBIiDADQEKEGQASIswAkBBhBoCECDMAJESYASAhwgwACRFmAEiIMANAQoQZABIizACQjM3i/wO+V3t/fTT5TgAAAABJRU5ErkJggg==)

#### 2.1 ScheduledThreadPoolExecutor 构造方法

1. public ScheduledThreadPoolExecutor(int corePoolSize)
2. public ScheduledThreadPoolExecutor(int corePoolSize, ThreadFactory threadFactory)
3. public ScheduledThreadPoolExecutor(int corePoolSize, RejectedExecutionHandler handler)
4. public ScheduledThreadPoolExecutor(int corePoolSize, ThreadFactory threadFactory,RejectedExecutionHandler handler) 


#### 2.2 ScheduledThreadPoolExecutor 实例化

1. 直接 new 出 ScheduledThreadPoolExecutor 类的实例

```
ScheduledThreadPoolExecutor scheduledExecutorService = new ScheduledThreadPoolExecutor(1);
```

2. 通过 Executors 类的 newScheduledThreadPool 静态方法。

```
ScheduledExecutorService scheduledExecutorService = Executors.newScheduledThreadPool(1);
```

## 3 scheduleWithFixedDelay 固定延迟执行

```java
import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Component
public class ScheuledCom {

    private static final Logger logger = LoggerFactory.getLogger(ScheuledCom.class);

    private static ScheduledExecutorService scheduledExecutorService = new ScheduledThreadPoolExecutor(1);

    @PostConstruct
    public void init() {
        logger.info("ScheuledCom init");
        scheduledExecutorService.scheduleWithFixedDelay(() -> {
            try {
                logger.info("ScheuledCom start task");
                long taskConsume = RandomUtils.nextLong(1, 5);
                TimeUnit.SECONDS.sleep(taskConsume);
                logger.info("ScheuledCom end task, consume = {}", taskConsume);
            } catch (Exception e) {
            }

        }, 3, 2, TimeUnit.SECONDS);
    }
}
```

- 输出如下

```
15:08:52.249 [main] INFO  c.c.payment.component.ScheuledCom - ScheuledCom init
15:08:55.299 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom start task
15:08:59.302 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom end task, consume = 4
15:09:01.306 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom start task
15:09:03.307 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom end task, consume = 2
15:09:05.308 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom start task
15:09:06.308 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom end task, consume = 1
15:09:08.310 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom start task
15:09:10.310 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom end task, consume = 2
15:09:12.311 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom start task
15:09:13.312 [pool-1-thread-1] INFO  c.c.payment.component.ScheuledCom - ScheuledCom end task, consume = 1
```

- scheduleWithFixedDelay 方法参数解释如下：

1. Runnable：任务接口对象，这里就是打印一下
2. initialDelay：表示首次延迟多长时间执行
3. delay：每次任务执行完毕后延迟多长时间后再次执行
4. TimeUnit：initialDelay 和 delay 的时间单位

- 关于 delay 参数需要注意以下问题：

1. delay 的设置跟任务执行时间没有关系，这个参数表示任意两个任务执行的间隔时间

## 4 scheduleAtFixedRate 固定频率执行

```java
import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Component
public class ScheuledCom2 {

    private static final Logger logger = LoggerFactory.getLogger(ScheuledCom2.class);

    private static ScheduledExecutorService scheduledExecutorService = new ScheduledThreadPoolExecutor(1);

    @PostConstruct
    public void init() {
        logger.info("ScheuledCom2 init");
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
                logger.info("ScheuledCom2 start task");
                long taskConsume = RandomUtils.nextLong(1, 5);
                TimeUnit.SECONDS.sleep(taskConsume);
                logger.info("ScheuledCom2 end task, consume = {}", taskConsume);
            } catch (Exception e) {
            }

        }, 3, 3, TimeUnit.SECONDS);
    }
}
```

- 输出如下

```
15:14:31.143 [main] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 init
15:14:34.194 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 start task
15:14:35.197 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 end task, consume = 1
15:14:37.193 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 start task
15:14:39.194 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 end task, consume = 2
15:14:40.193 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 start task
15:14:41.194 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 end task, consume = 1
15:14:43.193 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 start task
15:14:44.193 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 end task, consume = 1
15:14:46.194 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 start task
15:14:48.194 [pool-2-thread-1] INFO  c.c.payment.component.ScheuledCom2 - ScheuledCom2 end task, consume = 2
```

- scheduleAtFixedRate 方法参数解释如下：

1. Runnable：任务接口对象，这里就是打印一下
2. initialDelay：表示首次延迟多长时间执行
3. period：任务的执行频率
4. TimeUnit：initialDelay 和 period 的时间单位

- 关于 period 参数需要注意以下问题：

1. 如果 Runnable 任务的处理时长 大于 period，那么当 Runnable 任务执行完毕后会立即重复执行
2. 如果 Runnable 任务的处理时长 小于或者等于 period，那么两个 Runnable 任务执行的时间间隔等于 period

## 5 使用建议

1. ScheduledThreadPoolExecutor 对象用于周期性的执行任务，因此任务数最好和 corePoolSize 一致。