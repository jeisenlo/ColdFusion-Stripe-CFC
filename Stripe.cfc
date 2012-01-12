/*
Copyright 2012 James Eisenlohr

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

component name="Stripe" output=false accessors=true description="ColdFusion Wrapper for Stripe.com API" {
    
    property string stripeApiKey; // Stripe Secret Publishable Key
    property string baseUrl;
    property string currency; // Stripe currently has only 'usd' support
    
    public stripe function init(required string stripeApiKey, string baseUrl='https://api.stripe.com/v1/', string currency='usd') {
        
        setStripeApiKey(arguments.stripeApiKey);
        setBaseUrl(arguments.baseUrl);
        setCurrency(arguments.currency);
        
        return this;
    }
    
    
/* CHARGES */
    
    public struct function createCharge(required numeric amount, string currency=getCurrency(), string customer='', any card, string description='') {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'charges');
        local.amount = amountToCents(arguments.amount); // convert amount to cents for Stripe
        local.HTTPService.addParam(type='formfield',name='amount',value=local.amount);
        local.HTTPService.addParam(type='formfield',name='currency',value=arguments.currency);
        if (Len(Trim(arguments.customer))) {
        	local.HTTPService.addParam(type='formfield',name='customer',value=Trim(arguments.customer));
        }
        if (StructKeyExists(arguments,'card') AND isStruct(arguments.card)) {
            local.HTTPService.addParam(type='formfield',name='card[number]',value=arguments.card.number);
            local.HTTPService.addParam(type='formfield',name='card[exp_month]',value=arguments.card.exp_month);
            local.HTTPService.addParam(type='formfield',name='card[exp_year]',value=arguments.card.exp_year);
            if (StructKeyExists(arguments,'card.cvc')) {
            	local.HTTPService.addParam(type='formfield',name='card[cvc]',value=arguments.card.cvc);
            }
            if (StructKeyExists(arguments,'card.name') AND Len(Trim(arguments.card.name))) {
            	local.HTTPService.addParam(type='formfield',name='card[name]',value=arguments.card.name);
            }
            if (StructKeyExists(arguments,'card.address_line1') AND Len(Trim(arguments.card.address_line1))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line1]',value=arguments.card.address_line1);
            }
            if (StructKeyExists(arguments,'card.address_line2') AND Len(Trim(arguments.card.address_line2))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line2]',value=arguments.card.address_line2);
            }
            if (StructKeyExists(arguments,'card.address_zip') AND Len(Trim(arguments.card.address_zip))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_zip]',value=arguments.card.address_zip);
            }
            if (StructKeyExists(arguments,'card.address_state') AND Len(Trim(arguments.card.address_state))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_state]',value=arguments.card.address_state);
            }
            if (StructKeyExists(arguments,'card.address_country') AND Len(Trim(arguments.card.address_country))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_country]',value=arguments.card.address_country);
            }
        } else if (StructKeyExists(arguments,'card')) {
        	local.HTTPService.addParam(type='formfield',name='card',value=Trim(arguments.card));
        }
        if (Len(Trim(arguments.description))) {
        	local.HTTPService.addParam(type='formfield',name='description',value=Trim(arguments.description));
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    } 
    
    // Can get X number of charges (0 to 100, 10 is default), a specific charge or all charges for a specific customer
    public struct function readCharge(string chargeid='', string customerid='', numeric count, numeric offset) {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'charges';
        if (Len(Trim(arguments.chargeid))) {
        	local.url = local.url & '/' & arguments.chargeid;
        } else if (Len(Trim(arguments.customerid))) {
        	local.url = local.url & '?customer=' & arguments.customerid;
        }
        if (StructKeyExists(arguments,'count') AND (arguments.count GT 0 AND arguments.count LTE 100)) {
        	// Regex to find ?
            if (Find('?',local.url) GT 0) {
        		local.url = local.url & '&count=' & arguments.count;
            } else {
            	local.url = local.url & '?count=' & arguments.count;
           	}
        }
        if (StructKeyExists(arguments,'offset') AND (arguments.offset GT 0)) {
        	// Regex to find ?
           if (Find('?',local.url) GT 0) {
         		local.url = local.url & '&offset=' & arguments.offset;
           } else {
            	local.url = local.url & '?offset=' & arguments.offset;
           }
        }
        local.HTTPService.setUrl(local.url);
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }  
    
    public struct function refundCharge(required string chargeid, numeric amount) {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'charges/' & arguments.chargeid & '/refund');
        if (StructKeyExists(arguments,'amount') AND arguments.amount GT 0) {
            local.HTTPService.addParam(type='formfield',name='amount',value=arguments.amount);
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }

    
/* CUSTOMERS */
    
    public struct function createCustomer(any card, string coupon='', string email='', string description='', string plan='', timestamp trial_end) {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'customers');
        if (StructKeyExists(arguments,'card') AND isStruct(arguments.card)) {
            local.HTTPService.addParam(type='formfield',name='card[number]',value=arguments.card.number);
            local.HTTPService.addParam(type='formfield',name='card[exp_month]',value=arguments.card.exp_month);
            local.HTTPService.addParam(type='formfield',name='card[exp_year]',value=arguments.card.exp_year);
            if (StructKeyExists(arguments,'card.cvc')) {
            	local.HTTPService.addParam(type='formfield',name='card[cvc]',value=arguments.card.cvc);
            }
            if (StructKeyExists(arguments,'card.name') AND Len(Trim(arguments.card.name))) {
            	local.HTTPService.addParam(type='formfield',name='card[name]',value=arguments.card.name);
            }
            if (StructKeyExists(arguments,'card.address_line1') AND Len(Trim(arguments.card.address_line1))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line1]',value=Trim(arguments.card.address_line1));
            }
            if (StructKeyExists(arguments,'card.address_line2') AND Len(Trim(arguments.card.address_line2))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line2]',value=Trim(arguments.card.address_line2));
            }
            if (StructKeyExists(arguments,'card.address_zip') AND Len(Trim(arguments.card.address_zip))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_zip]',value=Trim(arguments.card.address_zip));
            }
            if (StructKeyExists(arguments,'card.address_state') AND Len(Trim(arguments.card.address_state))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_state]',value=Trim(arguments.card.address_state));
            }
            if (StructKeyExists(arguments,'card.address_country') AND Len(Trim(arguments.card.address_country))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_country]',value=Trim(arguments.card.address_country));
            }
        } else if (StructKeyExists(arguments,'card')) {
        	local.HTTPService.addParam(type='formfield',name='card',value=Trim(arguments.card));
        }
        if (Len(Trim(arguments.coupon))) {
        	local.HTTPService.addParam(type='formfield',name='coupon',value=Trim(arguments.coupon));
        }
        if (Len(Trim(arguments.email))) {
            local.HTTPService.addParam(type='formfield',name='email',value=Trim(arguments.email));
        }
        if (Len(Trim(arguments.description))) {
            local.HTTPService.addParam(type='formfield',name='description',value=Trim(arguments.description));
        }
        if (Len(Trim(arguments.plan))) {
            local.HTTPService.addParam(type='formfield',name='plan',value=Trim(arguments.plan));
        } 
        if (StructKeyExists(arguments,'trial_end') AND IsDate(arguments.trial_end)) {
        	loca.intUTCDate = timeToUTCInt(arguments.trial_end);
            local.HTTPService.addParam(type='formfield',name='trial_end',value=local.intUTCDate);
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function readCustomer(string customerid='', numeric count, numeric offset) {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'customers';
        if (Len(Trim(arguments.customerid))) {
        	local.HTTPService.setUrl(local.url & '/' & arguments.customerid);
        } else if (StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count);
        } else if (NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?offset=' & arguments.offset);
        } else {
        	local.HTTPService.setUrl(local.url);
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function updateCustomer(required string customerid, any card, string coupon='',string description='',string email='') {
    
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'customers/' & arguments.customerid);
        if (StructKeyExists(arguments,'card') AND isStruct(arguments.card)) {
            local.HTTPService.addParam(type='formfield',name='card[number]',value=arguments.card.number);
            local.HTTPService.addParam(type='formfield',name='card[exp_month]',value=arguments.card.exp_month);
            local.HTTPService.addParam(type='formfield',name='card[exp_year]',value=arguments.card.exp_year);
            if (StructKeyExists(arguments,'card.cvc')) {
            	local.HTTPService.addParam(type='formfield',name='card[cvc]',value=arguments.card.cvc);
            }
            if (StructKeyExists(arguments,'card.name') AND Len(Trim(arguments.card.name))) {
            	local.HTTPService.addParam(type='formfield',name='card[name]',value=arguments.card.name);
            }
            if (StructKeyExists(arguments,'card.address_line1') AND Len(Trim(arguments.card.address_line1))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line1]',value=Trim(arguments.card.address_line1));
            }
            if (StructKeyExists(arguments,'card.address_line2') AND Len(Trim(arguments.card.address_line2))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line2]',value=Trim(arguments.card.address_line2));
            }
            if (StructKeyExists(arguments,'card.address_zip') AND Len(Trim(arguments.card.address_zip))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_zip]',value=Trim(arguments.card.address_zip));
            }
            if (StructKeyExists(arguments,'card.address_state') AND Len(Trim(arguments.card.address_state))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_state]',value=Trim(arguments.card.address_state));
            }
            if (StructKeyExists(arguments,'card.address_country') AND Len(Trim(arguments.card.address_country))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_country]',value=Trim(arguments.card.address_country));
            }
        } else if (StructKeyExists(arguments,'card')) {
        	local.HTTPService.addParam(type='formfield',name='card',value=Trim(arguments.card));
        }
        if (Len(Trim(arguments.coupon))) {
        	local.HTTPService.addParam(type='formfield',name='coupon',value=Trim(arguments.coupon));
        }
        if (Len(Trim(arguments.description))) {
            local.HTTPService.addParam(type='formfield',name='description',value=Trim(arguments.description));
        }
        if (Len(Trim(arguments.email))) {
            local.HTTPService.addParam(type='formfield',name='email',value=Trim(arguments.email));
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function deleteCustomer(required string customerid) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('DELETE');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'customers/' & arguments.customerid);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }

   
/* CARD TOKENS */
    
    public struct function createToken(required struct card, numeric amount, string currency=getCurrency()) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'tokens');
        if (StructKeyExists(arguments,'card') AND isStruct(arguments.card)) {
            local.HTTPService.addParam(type='formfield',name='card[number]',value=arguments.card.number);
            local.HTTPService.addParam(type='formfield',name='card[exp_month]',value=arguments.card.exp_month);
            local.HTTPService.addParam(type='formfield',name='card[exp_year]',value=arguments.card.exp_year);
            if (StructKeyExists(arguments,'card.cvc')) {
            	local.HTTPService.addParam(type='formfield',name='card[cvc]',value=arguments.card.cvc);
            }
            if (StructKeyExists(arguments,'card.name') AND Len(Trim(arguments.card.name))) {
            	local.HTTPService.addParam(type='formfield',name='card[name]',value=arguments.card.name);
            }
            if (StructKeyExists(arguments,'card.address_line1') AND Len(Trim(arguments.card.address_line1))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line1]',value=Trim(arguments.card.address_line1));
            }
            if (StructKeyExists(arguments,'card.address_line2') AND Len(Trim(arguments.card.address_line2))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line2]',value=Trim(arguments.card.address_line2));
            }
            if (StructKeyExists(arguments,'card.address_zip') AND Len(Trim(arguments.card.address_zip))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_zip]',value=Trim(arguments.card.address_zip));
            }
            if (StructKeyExists(arguments,'card.address_state') AND Len(Trim(arguments.card.address_state))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_state]',value=Trim(arguments.card.address_state));
            }
            if (StructKeyExists(arguments,'card.address_country') AND Len(Trim(arguments.card.address_country))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_country]',value=Trim(arguments.card.address_country));
            }
        }
        if (StructKeyExists(arguments,'amount')) {
        	local.amount = amountToCents(arguments.amount); // convert amount to cents for Stripe
            local.HTTPService.addParam(type='formfield',name='amount',value=local.amount);
        }
        local.HTTPService.addParam(type='formfield',name='currency',value=arguments.currency);
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
	
    public struct function readToken(required string tokenid) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'tokens/' & arguments.tokenid);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    
/* PLANS */
    
    public struct function createPlan(required numeric amount, required string interval, required string name, string planid=CreateUUID(), string currency=getCurrency(), numeric trial_period_days) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'plans');
        local.HTTPService.addParam(type='formfield',name='id',value=Trim(arguments.planid));
        local.amount = amountToCents(arguments.amount);
        local.HTTPService.addParam(type='formfield',name='amount',value=local.amount);
        local.HTTPService.addParam(type='formfield',name='currency',value=Trim(arguments.currency));
        local.HTTPService.addParam(type='formfield',name='interval',value=Trim(arguments.interval));
        local.HTTPService.addParam(type='formfield',name='name',value=Trim(arguments.name));
        if (StructKeyExists(arguments,'trial_period_days')) {
        	local.HTTPService.addParam(type='formfield',name='trial_period_days',value=arguments.trial_period_days);
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function readPlan(string planid='', numeric count, numeric offset) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'plans';
        if (Len(Trim(arguments.planid))) {
        	local.HTTPService.setUrl(local.url & '/' & arguments.planid);
        } else if (StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count);
        } else if (NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?offset=' & arguments.offset);
        } else {
        	local.HTTPService.setUrl(local.url);
        }
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function updatePlan(required string planid, required string name) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'plans/' & arguments.planid);
        local.HTTPService.addParam(type='formfield',name='name',value=Trim(arguments.name));
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function deletePlan(required string planid) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('DELETE');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'plans/' & arguments.planid);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }


/* SUBCRIPTIONS */
 	
    public struct function updateSubscription(required string customerid, required string planid, string coupon='', boolean prorate=true, timestamp trial_end, any card) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'customers/' & arguments.customerid & '/subscription');
        if (Len(Trim(arguments.coupon))) {
        	local.HTTPService.addParam(type='formfield',name='coupon',value=Trim(arguments.coupon));
        }
        local.HTTPService.addParam(type='formfield',name='prorate',value=arguments.prorate);
        if (StructKeyExists(arguments,'trial_end') AND IsDate(arguments.trial_end)) {
        	loca.intUTCDate = timeToUTCInt(arguments.trial_end);
            local.HTTPService.addParam(type='formfield',name='trial_end',value=local.intUTCDate);
        }
        if (StructKeyExists(arguments,'card') AND isStruct(arguments.card)) {
            local.HTTPService.addParam(type='formfield',name='card[number]',value=arguments.card.number);
            local.HTTPService.addParam(type='formfield',name='card[exp_month]',value=arguments.card.exp_month);
            local.HTTPService.addParam(type='formfield',name='card[exp_year]',value=arguments.card.exp_year);
            if (StructKeyExists(arguments,'card.cvc')) {
            	local.HTTPService.addParam(type='formfield',name='card[cvc]',value=arguments.card.cvc);
            }
            if (StructKeyExists(arguments,'card.name') AND Len(Trim(arguments.card.name))) {
            	local.HTTPService.addParam(type='formfield',name='card[name]',value=arguments.card.name);
            }
            if (StructKeyExists(arguments,'card.address_line1') AND Len(Trim(arguments.card.address_line1))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line1]',value=Trim(arguments.card.address_line1));
            }
            if (StructKeyExists(arguments,'card.address_line2') AND Len(Trim(arguments.card.address_line2))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_line2]',value=Trim(arguments.card.address_line2));
            }
            if (StructKeyExists(arguments,'card.address_zip') AND Len(Trim(arguments.card.address_zip))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_zip]',value=Trim(arguments.card.address_zip));
            }
            if (StructKeyExists(arguments,'card.address_state') AND Len(Trim(arguments.card.address_state))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_state]',value=Trim(arguments.card.address_state));
            }
            if (StructKeyExists(arguments,'card.address_country') AND Len(Trim(arguments.card.address_country))) {
            	local.HTTPService.addParam(type='formfield',name='card[address_country]',value=Trim(arguments.card.address_country));
            }
        } else if (StructKeyExists(arguments,'card')) {
        	local.HTTPService.addParam(type='formfield',name='card',value=Trim(arguments.card));
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function deleteSubscription(required string customerid, boolean at_period_end=false) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('DELETE');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'customers/' & arguments.customerid & '/subscription');
        local.HTTPService.addParam(type='formfield',name='at_period_end',value=arguments.at_period_end);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }


/* INVOICE ITEMS */

	public struct function createInvoiceItem(required string customerid, required numeric amount, string currency=getCurrency(), string description='') {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'invoiceitems');
        local.HTTPService.addParam(type='formfield',name='customer',value=Trim(arguments.customerid));
        local.amount = amountToCents(arguments.amount); // convert amount to cents for Stripe
        local.HTTPService.addParam(type='formfield',name='amount',value=local.amount);
        local.HTTPService.addParam(type='formfield',name='currency',value=arguments.currency);       
        if (Len(Trim(arguments.description))) {
        	local.HTTPService.addParam(type='formfield',name='description',value=Trim(arguments.description));
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function readInvoiceItem(string invoiceitemid='', string customerid='', numeric count, numeric offset) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'invoiceitems';
        if (Len(Trim(arguments.invoiceitemid))) {
        	local.HTTPService.setUrl(local.url & '/' & arguments.invoiceitemid);
        } else if (Len(Trim(arguments.customerid)) AND StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customer & 'count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (Len(Trim(arguments.customerid)) AND StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customer & 'count=' & arguments.count);
        } else if (Len(Trim(arguments.customerid)) AND NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customer & '&offset=' & arguments.offset);
        } else if (Len(Trim(arguments.customerid))) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customer);
        } else if (StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count);
        } else if (NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?offset=' & arguments.offset);
        } else {
        	local.HTTPService.setUrl(local.url);
        }
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
	
    public struct function updateInvoiceItem(required string invoiceitemid, required numeric amount, string currency=getCurrency(), string description='') {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'invoiceitems/' & arguments.invoiceitemid);
        local.amount = amountToCents(arguments.amount);
        local.HTTPService.addParam(type='formfield',name='amount',value=local.amount);
        local.HTTPService.addParam(type='formfield',name='currency',value=Trim(arguments.currency));
        if (Len(Trim(arguments.description))) {
        	local.HTTPService.addParam(type='formfield',name='description',value=Trim(arguments.description));
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function deleteInvoiceItem(required string invoiceitemid) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('DELETE');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'invoiceitems/' & arguments.invoiceitemid);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    
/* INVOICES */
    
	public struct function readInvoice(string invoiceid='', string customerid='', numeric count, numeric offset, boolean upcoming=false) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'invoices';
        if (Len(Trim(arguments.invoiceid))) {
        	local.HTTPService.setUrl(local.url & '/' & arguments.invoiceid);
        } else if (Len(Trim(arguments.customerid)) AND StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customerid & 'count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (Len(Trim(arguments.customerid)) AND StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customerid & 'count=' & arguments.count);
        } else if (Len(Trim(arguments.customerid)) AND NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customerid & '&offset=' & arguments.offset);
        } else if (Len(Trim(arguments.customerid)) AND arguments.upcoming) {
        	local.HTTPService.setUrl(local.url & '/upcoming/?customer=' & arguments.customerid);
         } else if (Len(Trim(arguments.customerid)) AND NOT arguments.upcoming) {
        	local.HTTPService.setUrl(local.url & '?customer=' & arguments.customerid);
        } else if (StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count);
        } else if (NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?offset=' & arguments.offset);
        } else {
        	local.HTTPService.setUrl(local.url);
        }
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    
/* COUPONS */

	public struct function createCoupon(required numeric percent_off, required string duration, string couponid='', numeric duration_in_months, numeric max_redemptions, timestamp redeem_by) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('POST');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'coupons');
        local.HTTPService.addParam(type='formfield',name='percent_off',value=arguments.percent_off);
        local.HTTPService.addParam(type='formfield',name='duration',value=arguments.duration);
        if (Len(Trim(arguments.couponid))) {
        	local.HTTPService.addParam(type='formfield',name='id',value=arguments.couponid);
        }
        if (StructKeyExists(arguments,'duration_in_months')) {
        	local.HTTPService.addParam(type='formfield',name='duration_in_months',value=arguments.duration_in_months);
        }
        if (StructKeyExists(arguments,'max_redemptions')) {
        	local.HTTPService.addParam(type='formfield',name='max_redemptions',value=arguments.max_redemptions);
        }
        if (StructKeyExists(arguments,'redeem_by')) {
        	local.redeem_by = timeToUTCInt(arguments.redeem_by);
        	local.HTTPService.addParam(type='formfield',name='redeem_by',value=local.redeem_by);
        }
        local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
	
    public struct function readCoupon(string couponid='', numeric count, numeric offset) {
    	
        local.HTTPService = new HTTP();
        local.HTTPService.setMethod('GET');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.url = getBaseUrl() & 'coupons';
        if (Len(Trim(arguments.couponid))) {
        	local.HTTPService.setUrl(local.url & '/' & arguments.couponid);
        } else if (StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count & '&offset=' & arguments.offset);
        } else if (StructKeyExists(arguments,'count') AND NOT StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?count=' & arguments.count);
        } else if (NOT StructKeyExists(arguments,'count') AND StructKeyExists(arguments,'offset')) {
        	local.HTTPService.setUrl(local.url & '?offset=' & arguments.offset);
        } else {
        	local.HTTPService.setUrl(local.url);
        }
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }
    
    public struct function deleteCoupon(required string couponid) {
    
    	local.HTTPService = new HTTP();
        local.HTTPService.setMethod('DELETE');
        local.HTTPService.setCharset('utf-8');
        local.HTTPService.setUsername(getStripeApiKey());
        local.HTTPService.setUrl(getBaseUrl() & 'coupons/' & arguments.couponid);
    	local.HTTPResult = local.HTTPService.send().getPrefix();
        
        if (NOT isDefined("local.HTTPResult.status_code")) {
        	throw(errorcode="stripe_unresponsive", message="The Stripe server did not respond.", detail="The Stripe server did not respond.");
        } else if (local.HTTPResult.status_code NEQ "200") {
        	throw(errorcode=local.HTTPResult.status_code, message=local.HTTPResult.statuscode, detail=local.HTTPResult.filecontent);
        }
        return deserializeJSON(local.HTTPResult.filecontent);
    }

    
/* HELPER FUNCTIONS */    
    
    private numeric function amountToCents(required numeric amount) {
    	local.amount = arguments.amount * 100; // convert amount to cents for Stripe
        return local.amount;
    }
    
    public numeric function centsToAmount(required numeric cents) {
    	local.amount = arguments.cents / 100; // convert cents to dollars
        return local.amount;
    }
    
    private numeric function timeToUTCInt(required timestamp date) {
    	local.currUTCDate = DateConvert('local2utc',arguments.date);
        local.baseDate = CreateDateTime(1970,1,1,0,0,0);
        local.intUTCDate = DateDiff('s',local.baseDate,local.currUTCDate);
        return local.intUTCDate;
    }
    
    public datetime function utcIntToTime(required numeric intUtcTime) {
    	local.baseDate = CreateDateTime(1970,1,1,0,0,0);
        return DateAdd('s',arguments.intUtcTime,DateConvert('utc2Local',local.baseDate));;
    }
    
}