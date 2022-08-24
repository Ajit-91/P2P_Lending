import { Avatar, Box, Button, Typography } from '@mui/material'
import React, { useState } from 'react'
import { Card, Col, Row } from 'react-bootstrap'
import InputField from '../../components/InputField'
import Layout from '../../components/Layout'
import { useEth } from '../../contexts'
import SendIcon from '@mui/icons-material/Send';
import { useLocation, useNavigate } from 'react-router'

const CreateRequest = () => {

    const location = useLocation()
    const navigate = useNavigate()
    const {state} = location

    // if(!state || !state?.lenderAddress || !state?.lenderImage) {
    //     navigate('/borrower')
    // }

    const { state: { accounts, contracts, user } } = useEth();
    const [amount, setAmount] = useState('');
    const [purpose, setPurpose] = useState('');
    const [duration, setDuration] = useState('');
    const [bankStatement, setBankStatement] = useState('');


    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const res = await contracts.P2pLending.methods.createRequest(
                amount,
                purpose,
                duration,
                bankStatement
            ).send({ from: accounts[0] });
        } catch (error) {
            alert(error.message || "Something went wrong");
        }
    }

    console.log({ purpose, bankStatement, location })
    return (
        <Layout>
            <Typography align='center' sx={{ mb: 4 }}>Create Request</Typography>
            <Card body={true} className="shadow px-2" style={{ borderRadius: '10px' }}>
                <Box sx={{ display: "flex", justifyContent: 'center', alignItems: 'center' }}>
                    <Avatar
                        sx={{ width: 56, height: 56 }}
                        src={user?.image}
                    />
                    <hr style={{ width: '20%' }} />
                    <Avatar
                        sx={{ width: 56, height: 56 }}
                        src={state?.lenderImage}
                    />
                </Box>

                <form onSubmit={handleSubmit}>

                    <Row>
                        <Col lg={6}>
                            <InputField
                                label='sending request from Address'
                                value={accounts[0]}
                                readOnly
                                className='mb-3'
                            />
                        </Col>
                        <Col lg={6}>
                            <InputField
                                label='sending request to Address'
                                value={state?.lenderAddress || accounts[0]}
                                readOnly
                                className='mb-3'
                            />
                        </Col>
                    </Row>

                    <Row>
                        <Col lg={6}>
                            <InputField
                                label='Request amount'
                                type='number'
                                className='mb-3'
                                value={amount}
                                required
                                onChange={(e) => setAmount(e.target.value)}
                            />
                        </Col>
                        <Col lg={6}>
                            <InputField
                                label='Duration'
                                type='number'
                                className='mb-3'
                                value={duration}
                                required
                                onChange={(e) => setDuration(e.target.value)}
                            />
                        </Col>
                    </Row>

                    <InputField
                        label="Upload your recent 1 year bank statement"
                        type="file"
                        accept="application/pdf"
                        required
                        className='mb-3'
                        onChange={(e) => setBankStatement(e.target.files[0])}
                    />

                    <InputField
                        label="Purpose"
                        placeholder="Describe the purpose of loan in detail"
                        value={purpose}
                        required
                        as="textarea"
                        className='mb-3'
                        onChange={(e) => setPurpose(e.target.value)}
                    />

                    <Box sx={{ display: "grid", placeItems: 'center' }}>
                        <Button
                            type="submit"
                            sx={{ mt: 3, }}
                            variant="contained"
                            endIcon={<SendIcon />}
                        >Send Request
                        </Button>
                    </Box>

                </form>
            </Card>
        </Layout>
    )
}

export default CreateRequest