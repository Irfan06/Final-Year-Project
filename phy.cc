/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * Copyright (c) 1997 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the Computer Systems
 *	Engineering Group at Lawrence Berkeley Laboratory.
 * 4. Neither the name of the University nor of the Laboratory may be used
 *    to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *

 * @(#) $Header: 

 *
 * Ported from CMU/Monarch's code, nov'98 -Padma Haldar.
 * phy.cc
 */

#include <math.h>
#include <random.h>
#include "config.h"
#include <packet.h>
#include <phy.h>
#include <dsr/hdr_sr.h>


class Mac;

static int InterfaceIndex = 0;
int prim_status[11];
int sec_status[11];
int total_channels;
int cpacket_count[100];

Phy::Phy() : BiConnector() {
	index_ = InterfaceIndex++;
	bandwidth_ = 0.0;
	channel_ = 0;
	node_ = 0;
	head_ = 0;
        //carmen
        nchannel=0;
        for(int i=0;i<12;i++) {
              multichannel[i]=0;
        }
}

int
Phy::command(int argc, const char*const* argv) {
	if (argc == 2) {
		Tcl& tcl = Tcl::instance();

		if(strcmp(argv[1], "id") == 0) {
			tcl.resultf("%d", index_);
			return TCL_OK;
		}
	}

	else if(argc == 3) {

		TclObject *obj;

		if( (obj = TclObject::lookup(argv[2])) == 0) {
			fprintf(stderr, "%s lookup failed\n", argv[1]);
			return TCL_ERROR;
		}
		if (strcmp(argv[1], "channel") == 0) {
                        assert(channel_ == 0);
			channel_ = (Channel*) obj;
                        //multichannel[0] = (Channel*) obj;
                        nifaces++;
			downtarget_ = (NsObject*) obj;
			// LIST_INSERT_HEAD() is done by Channel
			return TCL_OK;
		}

		/*if (strcmp(argv[1], "n_channel") == 0) {
			int totalc= atoi(argv[2]);
			printf("\n totalc %d \n",totalc);
			return TCL_OK;
		}*/

                //carmen 
                if (strcmp(argv[1], "mchannel") == 0) {
                        assert(multichannel[nchannel] == 0);
		    	multichannel[nchannel] = (Channel*) obj;
                        nchannel++;
			total_channels = nchannel;
			//printf("\nnchannelnchannel %d \n",nchannel);
			downtarget_ = (NsObject*) obj;
			// LIST_INSERT_HEAD() is done by Channel
			return TCL_OK;
                }
		else if (strcmp(argv[1], "node") == 0) {
			assert(node_ == 0);
			node_ = (Node*) obj;
			// LIST_INSERT_HEAD() is done by Node
			return TCL_OK;
		}
		else if (strcmp(argv[1], "linkhead") == 0) {
			head_ = (LinkHead*)  obj;
			return (TCL_OK);
		}

	}
	return BiConnector::command(argc, argv);
}
//carmen
//change setchnl from inline
//to set multiple channels
void 
Phy::setchnl (Channel *chnl) 
{
   // printf("ssssssssssssssss \n");
         //channel_ = chnl;
         multichannel[nchannel]=chnl;

}


void
Phy::recv(Packet* p, Handler*)
{
	struct hdr_cmn *hdr = HDR_CMN(p);	
	struct hdr_ip *ih = HDR_IP(p);	
	//struct hdr_sr *hsr = HDR_SR(p);


        nchannel = hdr->channelindex_;

         ////////////////////////////////////

        /*if (hdr->fromprimaryuser == 1) 
        {

         nchannel = 2;

        }*/

        if(hdr->ptype_==PT_CBR && ih->aggregated_packet==0) {
		printf("\n Channel Selection for Intra Cluster Communication");
        	printf("\nphy: src=%d hdr->channelindex=%d index_=%d TC %d\n", ih->saddr(),hdr->channelindex_,node()->nodeid(),total_channels);
		int available_ch_count=0;
		int available_ch_list[4];
		if(hdr->channelindex_!=0 && node()->nodeid()==ih->saddr()) {
			printf("\nPrimary user: %d channel: %d \n", ih->saddr(),hdr->channelindex_);
			prim_status[hdr->channelindex_]=1;
		} else if(node()->nodeid()==ih->saddr()) {
			cpacket_count[ih->saddr()] = cpacket_count[ih->saddr()] + 1;
			printf("\nSecondary user: %d\n", ih->saddr());
			for(int k=1;k<total_channels;k++) {
				if(prim_status[k]==0 && (sec_status[k]==0 || sec_status[k]==node()->nodeid())) {
					available_ch_list[available_ch_count]=k;
					available_ch_count++;
					printf("\nChannel %d is idle\n", k);
				} else {
					printf("\nChannel %d is busy\n", k);
				}
			}
			int selected_channel=0;
			double min=10000.0;
			double E[4];
			int interval = 1;
			double duration = 15.0 - 5.0; // stope time - start time for data transmission		
			double ER = 0.2818 * duration;	
			double packet_count = duration / interval;
			double A = 512 * 8 * packet_count;
			double lamda[10];
			lamda[0] =0.5;
			for(int m=1;m<4;m++) {
			lamda[m] = Random::uniform(0,10) / 10;
			printf("\n lamda %f mmmmm %d \n",lamda[m],m);				
			}
			/*lamda[1] = 0.33;
			lamda[2] = 0.22;
			lamda[3] = 0.45;*/
			double residual_data = (512 * 8 * (packet_count - cpacket_count[ih->saddr()])); 
			printf("Residual Data %f nnn %d ccc %d packet_count %f\n",residual_data,ih->saddr(), cpacket_count[ih->saddr()],packet_count );

			for(int m1=0;m1<4;m1++) {

			E[m1] = (((A*ER*1.0) / (1.0-lamda[m1])) / 1000000.0);

			//printf("\n E[m1]a %f mmmmm %d \n",E[m1],m1);				
			
			}
			//E[0] = 0.8;E[1] = 0.5;E[2] = 0.7;E[3] = 0.3;
			printf("\navailable_ch_count=%d\n",available_ch_count);
			if(available_ch_count!=0) {
				for(int m=0;m<available_ch_count;m++) {
					int ach=available_ch_list[m];
					printf("\navailable_ch:%d\n",ach);
					if(E[ach]<min) {
						min=E[ach];
						selected_channel=ach;
					}
				}
			}
			if(selected_channel!=0) sec_status[selected_channel]=node()->nodeid();
			printf("Selected_channel=%d\n",selected_channel);
		} else {
			printf("router\n");
		}
	} else if(hdr->ptype_==PT_CBR && ih->aggregated_packet==1) {
		printf("\n Channel Selection for Inter Cluster Communication");
        	printf("\nphy: src=%d hdr->channelindex=%d index_=%d\n", ih->saddr(),hdr->channelindex_,node()->nodeid());
		int available_ch_count=0;
		int available_ch_list[4];
		if(hdr->channelindex_!=0 && node()->nodeid()==ih->saddr()) {
			printf("\nPrimary user: %d channel: %d \n", ih->saddr(),hdr->channelindex_);
			prim_status[hdr->channelindex_]=1;
		} else if(node()->nodeid()==ih->saddr()) {
			printf("\nSecondary user %d=\n", ih->saddr());
			for(int k=1;k<total_channels;k++) {
				if(prim_status[k]==0) {
					available_ch_list[available_ch_count]=k;
					available_ch_count++;
					printf("\nChannel %d is idle\n", k);
				} else {
					printf("\nChannel %d is busy\n", k);
				}
			}
			int selected_channel=0;
			double min=10000.0;
			double E[4];
			int interval = 1;
			double duration = 15.0 - 5.0; // stope time - start time for data transmission		
			double ER = 0.2818 * duration;	
			double packet_count = duration / interval;
			double A = 512 * 8 * packet_count;
			double lamda[10];
			lamda[0] =0.5;
			for(int m=1;m<4;m++) {
			lamda[m] = Random::uniform(0,10) / 10;
			//printf("\n cccclamda %f mmmmm %d \n",lamda[m],m);				
			}
			/*lamda[1] = 0.43;
			lamda[2] = 0.22;
			lamda[3] = 0.15;*/

			for(int m1=0;m1<4;m1++) {

			E[m1] = (((A*ER*1.0) / (1.0-lamda[m1])) / 1000000.0);

			//printf("\n CCEEEEEm1 %d E %f a %f er %f lamda[m1] %f\n",m1,E[m1],A,ER,lamda[m1]);
			}
			//E[0]=0.9;E[1]=0.5;E[2]=0.6;E[3]=0.4;
			printf("\navailable_ch_count=%d\n",available_ch_count);
			if(available_ch_count!=0) {
				for(int m=0;m<available_ch_count;m++) {
					int ach=available_ch_list[m];
					printf("\navailable_ch:%d\n",ach);
					if(E[ach]<min) {
						min=E[ach];
						selected_channel=ach;
					}
				}
			}
			printf("selected_channel=%d\n",selected_channel);
		} else {
			printf("router\n");
		}
	}
	
       // printf("phy_recv: index_ %d nchannel %d \n",index_,nchannel);
	
	/*
	 * Handle outgoing packets
	 */
	switch(hdr->direction()) {
	case hdr_cmn::DOWN :
		/*
		 * The MAC schedules its own EOT event so we just
		 * ignore the handler here.  It's only purpose
		 * it distinguishing between incoming and outgoing
		 * packets.
		 */
		sendDown(p);
		return;
	case hdr_cmn::UP :
		if (sendUp(p) == 0) {
			/*
			 * XXX - This packet, even though not detected,
			 * contributes to the Noise floor and hence
			 * may affect the reception of other packets.
			 */
			Packet::free(p);
			return;
		} else {
			uptarget_->recv(p, (Handler*) 0);
		}
		break;
	default:
		printf("Direction for pkt-flow not specified; Sending pkt up the stack on default.\n\n");
		if (sendUp(p) == 0) {
			/*
			 * XXX - This packet, even though not detected,
			 * contributes to the Noise floor and hence
			 * may affect the reception of other packets.
			 */
			Packet::free(p);
			return;
		} else {
			uptarget_->recv(p, (Handler*) 0);
		}
	}
	
}

/* NOTE: this might not be the best way to structure the relation
between the actual interfaces subclassed from net-if(phy) and 
net-if(phy). 
It's fine for now, but if we were to decide to have the interfaces
themselves properly handle multiple incoming packets (they currently
require assistance from the mac layer to do this), then it's not as
generic as I'd like.  The way it is now, each interface will have to
have it's own logic to keep track of the packets that are arriving.
Seems like this is general service that net-if could provide.

Ok.  A fair amount of restructuring is going to have to happen here
when/if net-if keep track of the noise floor at their location.  I'm
gonna punt on it for now.

Actually, this may be all wrong.  Perhaps we should keep a separate 
noise floor per antenna, which would mean the particular interface types
would have to track noise floor themselves, since only they know what
kind of antenna diversity they have.  -dam 8/7/98 */


// double
// Phy::txtime(Packet *p) const
// {
// 	hdr_cmn *hdr = HDR_CMN(p);
// 	return hdr->size() * 8.0 / Rb_;
// }


void
Phy::dump(void) const
{
	fprintf(stdout, "\tINDEX: %d\n",
		index_);
	fprintf(stdout, "\tuptarget: %lx, channel: %lx",
		(long) uptarget_, (long) channel_);

}


