﻿$filePath = 'your save path here\SANDBOX_0_0_0_.sbs'
$filePath2 = 'your save path here\SANDBOX.sbc'

# ===== only change the above values

[xml]$myXML = Get-Content $filePath
$ns = New-Object System.Xml.XmlNamespaceManager($myXML.NameTable)
$ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

[xml]$myXML2 = Get-Content $filePath2
$ns2 = New-Object System.Xml.XmlNamespaceManager($myXML2.NameTable)
$ns2.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")


#wipe orphaned id's (permanent death issue) if dead player owns nothing.
    [string]$compare = "360"
    $nodePIDs = $myXML2.SelectNodes("//Identities/MyObjectBuilder_Identity"  , $ns2)
    ForEach($node in $nodePIDs){
        $NPCID = [string]$node.PlayerId[0] + [string]$node.PlayerId[1] + [string]$node.PlayerId[2]
        $playerid = $node.PlayerId
        $client = $myXML2.SelectSingleNode("//DisconnectedPlayers/dictionary/item[Value='$playerid']" , $ns2)
        $clientcount= $client.count
        $nodeOwns = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]/CubeBlocks/MyObjectBuilder_CubeBlock[Owner='$playerid']"  , $ns).count
        IF($clientcount -eq 0 -and $nodeOwns -eq 0 -and $NPCID -ne $compare){
            $selectdelete = $myXML2.SelectSingleNode("//Factions/Factions/MyObjectBuilder_Faction/Members/MyObjectBuilder_FactionMember[PlayerId='$playerid']" , $ns2)
            Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
            Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)] is not a member of a faction, proceeding..."}
            $selectdelete = $myXML2.SelectSingleNode("//Factions/Players/dictionary/item[Key='$playerid']", $ns2)
            Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
            Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)]; no faction dictionary data found, proceeding..."}
            $selectdelete = $myXML2.SelectSingleNode("//Factions/Factions/MyObjectBuilder_Faction/JoinRequests/MyObjectBuilder_FactionMember[PlayerId='$playerid']" , $ns2)
            Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
            Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)] has no faction join requests, proceeding..."}
            $node.ParentNode.RemoveChild($node)
            Write-Host -ForegroundColor Green " abandoned ID deleted "
        } 
    }

# remove players who dont own anything    

    $nodePIDs = $myXML2.SelectNodes("//Identities/MyObjectBuilder_Identity"  , $ns2)
    ForEach($node in $nodePIDs){
                $nodeClientID=$myXML2.SelectSingleNode("//DisconnectedPlayers/dictionary/item[Value='$($node.PlayerId)']" , $ns2)
                $nodename = $nodeClientID.ParentNode.Item.Key.ClientId
                $nodeid = $node.PlayerId
                $nodeOwns = $myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]/CubeBlocks/MyObjectBuilder_CubeBlock[Owner='$nodeid']"  , $ns).Count
                If($nodeOwns -eq 0){
                  $selectdelete = $myXML2.SelectSingleNode("//Factions/Factions/MyObjectBuilder_Faction/Members/MyObjectBuilder_FactionMember[PlayerId='$nodeid']" , $ns2)
                  Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
                  Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)] is not a member of a faction, proceeding..."}
                  $selectdelete = $myXML2.SelectSingleNode("//Factions/Players/dictionary/item[Key='$nodeid']", $ns2)
                  Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
                  Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)]; no faction dictionary data found, proceeding..."}
                  $selectdelete = $myXML2.SelectSingleNode("//Factions/Factions/MyObjectBuilder_Faction/JoinRequests/MyObjectBuilder_FactionMember[PlayerId='$nodeid']" , $ns2)
                  Try{$selectdelete.ParentNode.RemoveChild($selectdelete)}
                  Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)] has no faction join requests, proceeding..."}
                  Try{$nodeClientID.ParentNode.RemoveChild($nodeClientID)}
                  Catch{Write-Host -ForegroundColor Green "[$($node.DisplayName)] has no connection status, proceeding..."}
                  $node.ParentNode.RemoveChild($node)
                  $deletedplayer = $deletedplayer + 1
                } 
    }

#remove empty factions
    $nodeFactions = $myXML2.SelectNodes("//Factions/Factions/MyObjectBuilder_Faction" , $ns2)
    ForEach($faction in $nodeFactions){
        $membercount = $faction.SelectNodes("Members/MyObjectBuilder_FactionMember" , $ns2).count
        $factionid = $faction.FactionId
        If($membercount -eq 0 -or $membercount -eq $null){
            $selectdelete = $myXML2.SelectNodes("//Factions/Requests/MyObjectBuilder_FactionRequests[FactionId='$factionid']" , $ns2)
            ForEach($selected in $selectdelete){
                $selected.ParentNode.RemoveChild($selected)
            }
            $selectdelete = $myXML2.SelectNodes("//Factions/Relations/MyObjectBuilder_FactionRelation[FactionId1='$factionid' or FactionId2='$factionid']" , $ns2)
            ForEach($selected in $selectdelete){
                $selected.ParentNode.RemoveChild($selected)
            }
            #Add-Content -Path $playerspath -Value "Deleted faction $($faction.Name) ..."
            #Write-Host -ForegroundColor Green "actioned! $membercount"
            $faction.ParentNode.RemoveChild($faction)
            $deletefactions = $deletefactions + 1
        }
        #IF($membercount -ne 0 -or $membercount-ne $null){Write-Host -ForegroundColor Green "no action $membercount"}
    }

    $myXML.Save($filePath)
    $myXML2.Save($filePath2)

